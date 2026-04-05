# frozen_string_literal: true

module Agents
  # Agents::ApplyApprovedMenuChangesJob runs every 30 minutes via Heroku Scheduler.
  # It finds AgentArtifacts of type `menu_optimization_changeset` that are:
  #   - status: approved
  #   - all AgentApproval records resolved (no pending ones)
  #   - scheduled_apply_at <= now
  #
  # For each matching artifact it applies the approved change actions through the
  # standard service layer (never direct SQL).
  #
  # Action application:
  #   section_reorder → update Menusection#sequence
  #   item_rename     → update Menuitem#name / #description
  #   item_suppress   → update Menuitem#hidden flag
  #   item_feature    → update Menuitem#hidden to false and ensure visible positioning
  #   image_queue     → already handled at approval time; noop here
  class ApplyApprovedMenuChangesJob < ApplicationJob
    queue_as :agent_default

    def perform
      applied = 0
      skipped = 0

      AgentArtifact.ready_to_apply.find_each do |artifact|
        run = artifact.agent_workflow_run

        # Verify all approvals are resolved
        if run.agent_approvals.pending.exists?
          Rails.logger.info(
            "[ApplyApprovedMenuChangesJob] Artifact #{artifact.id} has pending approvals — skipping",
          )
          skipped += 1
          next
        end

        did_apply = false
        artifact.with_lock do
          # Re-check status inside the lock — another worker may have applied it first
          next unless artifact.approved?

          apply_artifact(artifact)
          did_apply = true
        end

        if did_apply
          applied += 1
        else
          skipped += 1
        end
      rescue StandardError => e
        Rails.logger.error(
          "[ApplyApprovedMenuChangesJob] Failed to apply artifact #{artifact.id}: #{e.message}\n" \
          "#{e.backtrace&.first(3)&.join("\n")}",
        )
        skipped += 1
      end

      Rails.logger.info("[ApplyApprovedMenuChangesJob] Applied #{applied}, skipped #{skipped}")
    end

    private

    def apply_artifact(artifact)
      restaurant  = artifact.agent_workflow_run.restaurant
      actions     = Array(artifact.content['actions'])
      run         = artifact.agent_workflow_run

      # Only apply actions whose exact (action_type, target_id) pair was approved
      approved_pairs = run.agent_approvals
        .where(status: 'approved')
        .pluck(:action_type, :proposed_payload)
        .to_set { |at, pp| [at, pp['target_id']&.to_i] }

      actions.each do |action|
        action_type = action['action_type'].to_s
        next unless approved_pairs.include?([action_type, action['target_id']&.to_i])
        next if Agents::Workflows::MenuOptimizationWorkflow::ADVISORY_ONLY_ACTIONS.include?(action_type)
        # image_queue is handled at approval time
        next if action_type == 'image_queue'

        apply_action(action, restaurant)
      rescue StandardError => e
        Rails.logger.error(
          "[ApplyApprovedMenuChangesJob] Failed to apply action #{action_type} " \
          "on artifact #{artifact.id}: #{e.message}",
        )
      end

      artifact.apply!
      Rails.logger.info("[ApplyApprovedMenuChangesJob] Applied artifact #{artifact.id} for restaurant #{restaurant.id}")
    end

    def apply_action(action, restaurant)
      action_type = action['action_type'].to_s
      target_id   = action['target_id'].to_i

      if action_type == 'section_reorder'
        section = Menusection.joins(:menu)
          .where(menus: { restaurant_id: restaurant.id }, menusections: { id: target_id })
          .first
        return unless section

        new_sequence = action['new_sequence'].to_i
        section.update!(sequence: new_sequence) if new_sequence.positive?
        return
      end

      menuitem = restaurant.menus
        .joins(menusections: :menuitems)
        .where(menuitems: { id: target_id })
        .pick('menuitems.id')

      return unless menuitem

      mi = Menuitem.find_by(id: menuitem)
      return unless mi

      case action_type
      when 'item_rename'
        attrs = {}
        attrs[:name]        = action['new_name'].to_s         if action['new_name'].present?
        attrs[:description] = action['new_description'].to_s  if action['new_description'].present?
        mi.update!(attrs) if attrs.any?
      when 'item_suppress'
        mi.update!(hidden: true)
      when 'item_feature'
        mi.update!(hidden: false)
      end
    end
  end
end
