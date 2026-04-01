# frozen_string_literal: true

class ProfitMarginPolicy < ApplicationRecord
  DEFAULT_KEY = 'default'

  belongs_to :created_by_user, class_name: 'User', optional: true

  enum :status, { inactive: 0, active: 1 }

  validates :key, presence: true, uniqueness: true
  validates :target_gross_margin_pct,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :floor_gross_margin_pct,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :floor_below_target

  scope :active_policies, -> { active }
  scope :ordered, -> { order(created_at: :desc) }

  def self.current
    active.order(updated_at: :desc).first
  end

  private

  def floor_below_target
    return unless target_gross_margin_pct && floor_gross_margin_pct

    if floor_gross_margin_pct >= target_gross_margin_pct
      errors.add(:floor_gross_margin_pct, 'must be less than target gross margin')
    end
  end
end
