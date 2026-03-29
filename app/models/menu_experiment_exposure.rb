class MenuExperimentExposure < ApplicationRecord
  belongs_to :menu_experiment
  belongs_to :assigned_version, class_name: 'MenuVersion'
  belongs_to :dining_session

  validates :exposed_at, presence: true
  validates :dining_session_id, uniqueness: { scope: :menu_experiment_id,
                                              message: 'has already been exposed to this experiment', }
end
