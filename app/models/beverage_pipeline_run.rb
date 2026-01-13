class BeveragePipelineRun < ApplicationRecord
  belongs_to :menu
  belongs_to :restaurant

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :running, -> { where(status: 'running') }
end
