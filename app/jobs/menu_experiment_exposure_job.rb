# frozen_string_literal: true

# Records a single exposure event for a menu experiment.
# Idempotent: a no-op if the [dining_session_id, menu_experiment_id] pair already exists.
class MenuExperimentExposureJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: 3, backtrace: true

  # @param dining_session_id [Integer]
  # @param menu_experiment_id [Integer]
  # @param assigned_version_id [Integer]
  def perform(dining_session_id, menu_experiment_id, assigned_version_id)
    # Guard: all referenced records must still exist
    dining_session = DiningSession.find_by(id: dining_session_id)
    menu_experiment = MenuExperiment.find_by(id: menu_experiment_id)
    assigned_version = MenuVersion.find_by(id: assigned_version_id)

    unless dining_session && menu_experiment && assigned_version
      Rails.logger.warn(
        "[MenuExperimentExposureJob] skipping: record not found " \
        "(session=#{dining_session_id}, experiment=#{menu_experiment_id}, version=#{assigned_version_id})",
      )
      return
    end

    # Idempotent insert — no-op if already recorded for this session+experiment pair
    MenuExperimentExposure.find_or_create_by!(
      dining_session: dining_session,
      menu_experiment: menu_experiment,
    ) do |exposure|
      exposure.assigned_version = assigned_version
      exposure.exposed_at = Time.current
    end
  rescue ActiveRecord::RecordNotUnique
    # Race condition: another worker inserted the same record — safe to ignore
    Rails.logger.info(
      "[MenuExperimentExposureJob] duplicate exposure ignored for session=#{dining_session_id}, experiment=#{menu_experiment_id}",
    )
  end
end
