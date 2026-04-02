# frozen_string_literal: true

module Agents
  module Workflows
    # Agents::Workflows::MenuImportWorkflow orchestrates the 8-step AI menu import pipeline.
    # It is invoked by Agents::MenuImportWorkflowJob and delegates each step to
    # specialised logic. Resumable: re-running picks up from the last completed step.
    #
    # Pipeline:
    #   1. fetch_source     — retrieve raw OCR text from OcrMenuImport
    #   2. read_context     — load restaurant settings (currency, language, menus)
    #   3. extract_structure — LLM call to identify sections, items, prices, allergens
    #   4. normalise_and_tag — second LLM pass: normalise text, assign tags, score confidence
    #   5. policy_validate  — classify each item as auto_approve vs require_approval
    #   6. write_draft      — persist AgentArtifact with type menu_import_draft
    #   7. queue_enrichment — enqueue image / localisation jobs for applicable items
    #   8. notify_manager   — create AgentApproval records; email reviewer
    class MenuImportWorkflow
      STEP_NAMES = %w[
        fetch_source
        read_context
        extract_structure
        normalise_and_tag
        policy_validate
        write_draft
        queue_enrichment
        notify_manager
      ].freeze

      ALLERGEN_CONFIDENCE_THRESHOLD = 0.8
      AUTO_APPROVE_CONFIDENCE_THRESHOLD = 0.8
      LLM_MODEL = 'gpt-4o'
      LLM_TEMPERATURE_EXTRACT = 0.0 # deterministic for structure extraction
      LLM_TEMPERATURE_NORMALISE = 0.0

      def self.call(workflow_run)
        new(workflow_run).call
      end

      def initialize(workflow_run)
        @run = workflow_run
        @ocr_import_id = @run.context_snapshot['ocr_menu_import_id']
      end

      # Ensure all 8 steps exist before executing, then execute sequentially.
      def call
        provision_steps!

        @run.mark_running! if @run.pending?

        STEP_NAMES.each_with_index do |name, idx|
          step = @run.agent_workflow_steps.find_by(step_name: name, step_index: idx)
          next if step.nil? || step.completed? || step.skipped?

          execute_step(step)

          @run.reload
          break if @run.awaiting_approval? || @run.failed?
        end

        @run.reload
        complete_if_finished
      rescue StandardError => e
        Rails.logger.error("[MenuImportWorkflow] Run #{@run.id} failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
        @run.mark_failed!(e.message)
        mark_import_failed!(e.message)
      end

      private

      # Create all 8 AgentWorkflowStep rows up-front so progress is visible immediately.
      def provision_steps!
        existing_names = @run.agent_workflow_steps.pluck(:step_name)
        STEP_NAMES.each_with_index do |name, idx|
          next if existing_names.include?(name)

          @run.agent_workflow_steps.create!(
            step_name: name,
            step_index: idx,
            status: 'pending',
            input_snapshot: {},
            retry_count: 0,
          )
        end
      end

      def execute_step(step)
        step.mark_running!
        result = dispatch_step(step)
        step.mark_completed!(result)
      rescue StandardError => e
        step.mark_failed!(e)
        raise
      end

      def dispatch_step(step)
        case step.step_name
        when 'fetch_source'     then step_fetch_source
        when 'read_context'     then step_read_context
        when 'extract_structure' then step_extract_structure
        when 'normalise_and_tag' then step_normalise_and_tag
        when 'policy_validate'  then step_policy_validate
        when 'write_draft'      then step_write_draft
        when 'queue_enrichment' then step_queue_enrichment
        when 'notify_manager'   then step_notify_manager
        else
          raise "Unknown step: #{step.step_name}"
        end
      end

      # ---------------------------------------------------------------------------
      # Step 1: fetch_source
      # ---------------------------------------------------------------------------
      def step_fetch_source
        import = ocr_import
        mark_import_status!('processing')

        # Aggregate all OCR text from existing sections/items
        raw_text = import.ocr_menu_sections.includes(:ocr_menu_items).map do |section|
          lines = ["## #{section.name}"]
          section.ocr_menu_items.ordered.each do |item|
            line = "- #{item.name}"
            line += " — #{item.description}" if item.description.present?
            line += " (#{item.price})" if item.price.present?
            line += " [allergens: #{item.allergens.join(', ')}]" if item.allergens.any?
            lines << line
          end
          lines.join("\n")
        end.join("\n\n")

        {
          ocr_menu_import_id: import.id,
          raw_text: raw_text,
          source_locale: import.source_locale,
          sections_count: import.ocr_menu_sections.count,
          items_count: import.ocr_menu_items.count,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 2: read_context
      # ---------------------------------------------------------------------------
      def step_read_context
        restaurant = @run.restaurant

        existing_menus = restaurant.menus
          .where.not(status: 'archived')
          .includes(:menusections)
          .limit(5)
          .map do |menu|
            {
              id: menu.id,
              name: menu.name,
              section_names: menu.menusections.map(&:name),
            }
          end

        {
          restaurant_id: restaurant.id,
          name: restaurant.name,
          currency: restaurant.currency,
          country: restaurant.country,
          source_locale: ocr_import.source_locale,
          existing_menus: existing_menus,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 3: extract_structure
      # LLM call at temperature 0 to produce structured JSON from raw text.
      # ---------------------------------------------------------------------------
      def step_extract_structure
        fetch_output = completed_step_output('fetch_source')
        context_output = completed_step_output('read_context')

        raw_text = fetch_output&.dig('raw_text').to_s
        currency = context_output&.dig('currency') || 'EUR'

        system_prompt = <<~PROMPT
          You are a menu data extraction specialist. Extract the menu structure from the raw text below.
          Return ONLY a valid JSON object with this exact shape:
          {
            "sections": [
              {
                "name": "string",
                "items": [
                  {
                    "name": "string",
                    "description": "string or null",
                    "price": number or null,
                    "allergens": ["string"],
                    "is_vegetarian": boolean,
                    "is_vegan": boolean,
                    "is_gluten_free": boolean
                  }
                ]
              }
            ]
          }
          Currency: #{currency}. If prices are not present, use null. Do not invent data.
        PROMPT

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: "RAW MENU TEXT:\n#{raw_text}" },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE_EXTRACT,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed = parse_json_from_llm(content)

        { extracted_sections: parsed.fetch('sections', []) }
      rescue JSON::ParserError, KeyError => e
        raise "Failed to parse LLM structure extraction response: #{e.message}"
      end

      # ---------------------------------------------------------------------------
      # Step 4: normalise_and_tag
      # Second LLM pass: clean up OCR noise, assign tags, score confidence.
      # ---------------------------------------------------------------------------
      def step_normalise_and_tag
        extracted = completed_step_output('extract_structure')&.dig('extracted_sections') || []

        system_prompt = <<~PROMPT
          You are a menu normalisation expert. For each menu item:
          1. Fix OCR noise (typos, inconsistent spacing, incorrect capitalisation).
          2. Assign zero or more tags from: [vegan, gluten-free, spicy, premium, kids, high-margin, dairy-free, nut-free].
          3. Score your confidence (0.0 to 1.0) that the name, price, and allergens are correct.
          4. Flag any ambiguities in an "ambiguities" array (e.g. "price unclear", "allergen uncertain").
          Return the same JSON structure with added "tags", "confidence_score", and "ambiguities" fields per item.
          Never add allergen claims that were not present in the input.
          Return ONLY the JSON object with a "sections" key.
        PROMPT

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: "EXTRACTED SECTIONS:\n#{extracted.to_json}" },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE_NORMALISE,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed = parse_json_from_llm(content)
        normalised_sections = parsed.fetch('sections', [])

        # Persist normalised data back to OcrMenuItem records
        persist_normalised_items!(normalised_sections)

        { normalised_sections: normalised_sections }
      rescue JSON::ParserError, KeyError => e
        raise "Failed to parse LLM normalisation response: #{e.message}"
      end

      # ---------------------------------------------------------------------------
      # Step 5: policy_validate
      # Classify each item as auto_approved or require_approval.
      # Allergen claims ALWAYS require approval regardless of confidence.
      # ---------------------------------------------------------------------------
      def step_policy_validate
        counts = { auto_approved: 0, require_approval: 0 }

        ocr_import.ocr_menu_items.find_each do |item|
          status = if item.allergen_flagged?
                     'require_approval'
                   elsif item.confidence_score.nil? || item.confidence_score < AUTO_APPROVE_CONFIDENCE_THRESHOLD
                     'require_approval'
                   else
                     'auto_approved'
                   end

          item.update_column(:agent_approval_status, status)
          counts[status.to_sym] += 1
        end

        {
          auto_approved_count: counts[:auto_approved],
          require_approval_count: counts[:require_approval],
        }
      end

      # ---------------------------------------------------------------------------
      # Step 6: write_draft
      # Persist the normalised, validated item set as an AgentArtifact.
      # Update OcrMenuImport with reference to the run.
      # ---------------------------------------------------------------------------
      def step_write_draft
        normalised = completed_step_output('normalise_and_tag')&.dig('normalised_sections') || []
        policy_output = completed_step_output('policy_validate') || {}

        draft_content = {
          ocr_menu_import_id: ocr_import.id,
          sections: normalised,
          auto_approved_count: policy_output['auto_approved_count'],
          require_approval_count: policy_output['require_approval_count'],
          generated_at: Time.current.iso8601,
        }

        result = Agents::ArtifactWriter.call(
          workflow_run: @run,
          artifact_type: 'menu_import_draft',
          content: draft_content,
        )

        raise "ArtifactWriter failed: #{result.error}" unless result.success?

        # Link the import to this workflow run
        ocr_import.update_columns(
          agent_workflow_run_id: @run.id,
          agent_status: 'awaiting_approval',
        )

        { artifact_id: result.artifact.id }
      end

      # ---------------------------------------------------------------------------
      # Step 7: queue_enrichment
      # Enqueue image generation and localisation for applicable items.
      # ---------------------------------------------------------------------------
      def step_queue_enrichment
        enqueued_images = 0
        enqueued_localisation = 0

        ocr_import.ocr_menu_sections.includes(:ocr_menu_items).find_each do |section|
          section.ocr_menu_items.auto_approved.each do |item|
            # Queue image generation for items without an image
            next if item.image_prompt.blank?

            begin
              MenuItemImageGeneratorJob.perform_later(item.id, 'ocr_menu_item') if defined?(MenuItemImageGeneratorJob)
              enqueued_images += 1
            rescue StandardError => e
              Rails.logger.warn("[MenuImportWorkflow] Image enqueue failed for item #{item.id}: #{e.message}")
            end
          end
        end

        # Queue localisation if the source locale differs from restaurant default
        restaurant = @run.restaurant
        source_locale = ocr_import.source_locale
        if source_locale.present? && source_locale != restaurant.try(:default_locale)
          begin
            menu_id = ocr_import.menu_id
            if menu_id.present?
              MenuLocalizationJob.perform_async('menu', menu_id)
              enqueued_localisation += 1
            end
          rescue StandardError => e
            Rails.logger.warn("[MenuImportWorkflow] Localisation enqueue failed: #{e.message}")
          end
        end

        {
          enqueued_images: enqueued_images,
          enqueued_localisation: enqueued_localisation,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 8: notify_manager
      # Create AgentApproval records for all require_approval items and email reviewer.
      # ---------------------------------------------------------------------------
      def step_notify_manager
        artifact_id = completed_step_output('write_draft')&.dig('artifact_id')
        artifact = AgentArtifact.find_by(id: artifact_id)

        require_approval_items = ocr_import.ocr_menu_items.require_approval.to_a
        approvals_created = 0

        if require_approval_items.any?
          step = @run.agent_workflow_steps.find_by(step_name: 'notify_manager')

          require_approval_items.each do |item|
            Agents::ApprovalRouter.call(
              workflow_run: @run,
              action_type: 'menu_item_publish',
              risk_level: item.allergen_flagged? ? 'high' : 'medium',
              proposed_payload: {
                ocr_menu_item_id: item.id,
                name: item.name,
                price: item.price,
                allergens: item.allergens,
                confidence_score: item.confidence_score,
                reason: item.allergen_flagged? ? 'allergen_claim' : 'low_confidence',
              },
              step: step,
            )
            approvals_created += 1
          end
        else
          # All items auto-approved — mark import as ready for review
          ocr_import.update_column(:agent_status, 'awaiting_approval')
        end

        {
          approvals_created: approvals_created,
          artifact_id: artifact&.id,
        }
      end

      # ---------------------------------------------------------------------------
      # Helpers
      # ---------------------------------------------------------------------------

      def ocr_import
        @ocr_import ||= OcrMenuImport.find(@ocr_import_id)
      end

      def completed_step_output(step_name)
        step = @run.agent_workflow_steps.find_by(step_name: step_name, status: 'completed')
        step&.output_snapshot
      end

      def openai_client
        @openai_client ||= OpenaiClient.new
      end

      def mark_import_status!(status)
        ocr_import.update_column(:agent_status, status)
      rescue StandardError => e
        Rails.logger.warn("[MenuImportWorkflow] Could not update import status: #{e.message}")
      end

      def mark_import_failed!(message)
        ocr_import.update_columns(agent_status: 'failed')
      rescue StandardError => e
        Rails.logger.warn("[MenuImportWorkflow] Could not mark import failed: #{e.message}")
      end

      def complete_if_finished
        return if @run.awaiting_approval? || @run.failed? || @run.cancelled?

        all_done = @run.agent_workflow_steps.reload.all? { |s| s.completed? || s.skipped? }
        if all_done
          @run.mark_completed!
          ocr_import.update_column(:agent_status, 'awaiting_approval')
        end
      end

      # Persist normalised section/item data back onto existing OcrMenuSection / OcrMenuItem records.
      def persist_normalised_items!(normalised_sections)
        return if normalised_sections.blank?

        normalised_sections.each_with_index do |section_data, _s_idx|
          section_name = section_data['name'].to_s.strip
          items_data = Array(section_data['items'])

          # Match by name to the closest existing section
          section = ocr_import.ocr_menu_sections
            .order(Arel.sql("LOWER(TRIM(name)) = LOWER(TRIM('#{section_name.gsub("'", "''")}')) DESC"))
            .first
          next unless section

          items_data.each_with_index do |item_data, i_idx|
            item_name = item_data['name'].to_s.strip
            item = section.ocr_menu_items.order(sequence: :asc).offset(i_idx).first
            next unless item

            updates = {
              name: item_name.presence || item.name,
              confidence_score: item_data['confidence_score']&.to_f,
              proposed_tags: Array(item_data['tags']),
            }
            updates[:description] = item_data['description'] if item_data.key?('description')
            updates[:price] = item_data['price'] if item_data['price'].present?

            item.update_columns(updates)
          end
        end
      rescue StandardError => e
        Rails.logger.warn("[MenuImportWorkflow] persist_normalised_items! failed: #{e.message}")
      end

      # Extract JSON from an LLM response that may have surrounding prose or markdown fences.
      def parse_json_from_llm(content)
        # Strip markdown fences if present
        stripped = content.gsub(/```(?:json)?\n?/, '').gsub('```', '').strip
        JSON.parse(stripped)
      rescue JSON::ParserError
        # Try to extract just the JSON object portion
        match = content.match(/\{.*\}/m)
        raise JSON::ParserError, 'No JSON object found in LLM response' unless match

        JSON.parse(match[0])
      end
    end
  end
end
