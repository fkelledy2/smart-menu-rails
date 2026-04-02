# frozen_string_literal: true

# AgentPolicy defines per-restaurant approval rules for each action_type.
# A nil restaurant_id means this is a global default.
# Restaurant-scoped records override global defaults.
# Managed by mellow.menu admin in v1; owner-level overrides are v2.
class AgentPolicy < ApplicationRecord
  # Global default action types and their auto-approve settings.
  # These are seeded on restaurant creation.
  GLOBAL_DEFAULTS = [
    { action_type: 'read_restaurant_context', auto_approve: true, risk_level: 'low' },
    { action_type: 'search_menu_items',       auto_approve: true, risk_level: 'low' },
    { action_type: 'compose_manager_summary', auto_approve: true, risk_level: 'low' },
    { action_type: 'propose_menu_patch',      auto_approve: false, risk_level: 'medium' },
    { action_type: 'flag_item_unavailable',   auto_approve: false, risk_level: 'medium' },
    { action_type: 'generate_menu_image',     auto_approve: false, risk_level: 'low' },
    { action_type: 'write_draft_translation', auto_approve: false, risk_level: 'medium' },
    { action_type: 'fetch_menu_source',       auto_approve: true, risk_level: 'low' },
    { action_type: 'create_review_queue_task', auto_approve: true, risk_level: 'low' },
  ].freeze

  belongs_to :restaurant, optional: true

  validates :action_type, presence: true
  validates :approval_expiry_hours, numericality: { greater_than: 0 }

  scope :active,     -> { where(active: true) }
  scope :global,     -> { where(restaurant_id: nil) }
  scope :for_restaurant, ->(restaurant_id) { where(restaurant_id: restaurant_id) }

  # Seed global default policies — called on restaurant creation.
  def self.seed_defaults_for(restaurant)
    GLOBAL_DEFAULTS.each do |defaults|
      find_or_create_by!(
        restaurant: restaurant,
        action_type: defaults[:action_type],
      ) do |policy|
        policy.auto_approve = defaults[:auto_approve]
        policy.active       = true
      end
    end
  end
end
