# frozen_string_literal: true

class PairingRecommendation < ApplicationRecord
  belongs_to :drink_menuitem, class_name: 'Menuitem'
  belongs_to :food_menuitem, class_name: 'Menuitem'

  validates :drink_menuitem_id, uniqueness: { scope: :food_menuitem_id }

  scope :top_pairings, ->(drink_id) { where(drink_menuitem_id: drink_id).order(score: :desc) }
  scope :best_matches, -> { where(pairing_type: 'complement').order(score: :desc) }
  scope :surprising, -> { where(pairing_type: 'surprise').order(score: :desc) }

  def display_score
    (score.to_f * 100).round(0)
  end
end
