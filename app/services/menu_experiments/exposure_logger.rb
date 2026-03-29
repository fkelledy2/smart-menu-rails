# frozen_string_literal: true

module MenuExperiments
  # Enqueues an asynchronous job to record that a dining session was served
  # a particular menu version under an active experiment.
  #
  # Must not raise — errors are logged and swallowed to protect the render path.
  class ExposureLogger
    # @param dining_session [DiningSession]
    # @param menu_experiment [MenuExperiment]
    # @param assigned_version [MenuVersion]
    def self.log(dining_session, menu_experiment, assigned_version)
      MenuExperimentExposureJob.perform_later(
        dining_session.id,
        menu_experiment.id,
        assigned_version.id,
      )
    rescue StandardError => e
      Rails.logger.warn(
        "[MenuExperiments::ExposureLogger] failed to enqueue exposure job: #{e.class}: #{e.message}",
      )
    end
  end
end
