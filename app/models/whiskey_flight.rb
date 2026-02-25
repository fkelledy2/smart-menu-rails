# frozen_string_literal: true

class WhiskeyFlight < ApplicationRecord
  belongs_to :menu

  enum :source, { ai: 'ai', manual: 'manual' }, default: :ai
  enum :status, { draft: 'draft', published: 'published', archived: 'archived' }, default: :draft

  validates :theme_key, presence: true, uniqueness: { scope: :menu_id }
  validates :title, presence: true
  validates :items, presence: true
  validates :source, inclusion: { in: sources.keys }
  validates :status, inclusion: { in: statuses.keys }

  scope :visible, -> { where(status: 'published') }

  def display_price
    custom_price.presence || total_price
  end

  def per_dram_price
    dp = display_price
    return nil unless dp&.positive? && items.is_a?(Array) && items.any?

    (dp / items.size).round(2)
  end

  def savings
    return nil unless custom_price.present? && total_price.present?
    return nil unless custom_price < total_price

    (total_price - custom_price).round(2)
  end

  def recalculate_total_price!
    return unless items.is_a?(Array) && items.any?

    menuitem_ids = items.filter_map { |i| i['menuitem_id'] || i[:menuitem_id] }
    prices = Menuitem.where(id: menuitem_ids).pluck(:price).compact.map(&:to_f)
    update!(total_price: prices.sum.round(2))
  end
end
