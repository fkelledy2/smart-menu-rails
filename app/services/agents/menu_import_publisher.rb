# frozen_string_literal: true

module Agents
  # Agents::MenuImportPublisher promotes an approved AgentArtifact (menu_import_draft)
  # to live Menuitem records via the existing ImportToMenu service.
  # This is the ONLY path from agent output to a live menu — direct writes are prohibited.
  #
  # Pre-conditions:
  #   - The AgentWorkflowRun must not have any pending AgentApproval records.
  #   - The OcrMenuImport.status must be 'completed' (OCR pipeline finished).
  #   - All OcrMenuItem records with allergen claims must be approved.
  class MenuImportPublisher
    Result = Struct.new(:success?, :menu, :error, keyword_init: true)

    def self.call(workflow_run:, ocr_import:, restaurant:, published_by:)
      new(
        workflow_run: workflow_run,
        ocr_import: ocr_import,
        restaurant: restaurant,
        published_by: published_by,
      ).call
    end

    def initialize(workflow_run:, ocr_import:, restaurant:, published_by:)
      @run           = workflow_run
      @ocr_import    = ocr_import
      @restaurant    = restaurant
      @published_by  = published_by
    end

    def call
      validate!

      # Mark agent-approved items as confirmed so ImportToMenu picks them up
      confirm_approved_items!

      # Use existing ImportToMenu service for the actual promotion
      import_service = ImportToMenu.new(restaurant: @restaurant, import: @ocr_import)
      menu = if @ocr_import.menu_id.present?
               import_service.upsert_into_menu(Menu.find(@ocr_import.menu_id))
               Menu.find(@ocr_import.menu_id)
             else
               import_service.call
             end

      # Mark the artifact as applied
      artifact = @run.agent_artifacts
        .where(artifact_type: 'menu_import_draft')
        .order(created_at: :desc)
        .first
      artifact&.apply!

      # Update import agent_status
      @ocr_import.update_columns(agent_status: 'published')

      # Complete the workflow run
      @run.mark_completed! unless @run.completed?

      Result.new(success?: true, menu: menu)
    rescue StandardError => e
      Rails.logger.error("[Agents::MenuImportPublisher] Failed: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      Result.new(success?: false, error: e.message)
    end

    private

    def validate!
      if @run.agent_approvals.pending.exists?
        raise 'Cannot publish: there are pending approvals that must be resolved first.'
      end

      unless @ocr_import.completed? || @ocr_import.ocr_menu_sections.confirmed.any?
        raise 'Cannot publish: the OCR import has no confirmed sections.'
      end
    end

    # Auto-approve OCR items that were approved by the agent or the manager.
    # Items with status 'approved' or 'auto_approved' are confirmed for ImportToMenu.
    # Items with status 'rejected' are unconfirmed (skipped).
    def confirm_approved_items!
      @ocr_import.ocr_menu_sections.includes(:ocr_menu_items).find_each do |section|
        has_confirmed_items = false

        section.ocr_menu_items.find_each do |item|
          case item.agent_approval_status
          when 'auto_approved', 'approved'
            item.update_column(:is_confirmed, true)
            has_confirmed_items = true
          when 'rejected'
            item.update_column(:is_confirmed, false)
          else
            # Items without agent status: confirm if not allergen-flagged and confidence >= threshold
            if !item.allergen_flagged? && item.confidence_score.to_f >= 0.8
              item.update_column(:is_confirmed, true)
              has_confirmed_items = true
            else
              item.update_column(:is_confirmed, false)
            end
          end
        end

        # Confirm the section if it has at least one confirmed item
        section.update_column(:is_confirmed, has_confirmed_items)
      end
    end
  end
end
