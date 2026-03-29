# frozen_string_literal: true

module MenuExperiments
  # Deterministically assigns a dining session to the control or variant version
  # of a menu experiment.
  #
  # Algorithm: MD5 hash of "session_token:experiment_id" converted to an integer,
  # modulo 100. If the result is less than allocation_pct, the session is assigned
  # to the variant; otherwise control.
  #
  # This is O(1), purely functional, and adds negligible latency to the render path.
  # Must remain side-effect free — no writes, no enqueues.
  class VersionAssignmentService
    # @param dining_session [DiningSession]
    # @param menu_experiment [MenuExperiment]
    # @return [MenuVersion] the assigned version (control or variant)
    def self.assign(dining_session:, menu_experiment:)
      hash_input = "#{dining_session.session_token}:#{menu_experiment.id}"
      bucket = Digest::MD5.hexdigest(hash_input).to_i(16) % 100

      if bucket < menu_experiment.allocation_pct
        menu_experiment.variant_version
      else
        menu_experiment.control_version
      end
    end
  end
end
