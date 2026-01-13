class Menu::PublishSommelierJob
  include Sidekiq::Job

    sidekiq_options queue: 'default', retry: 3

    def perform(pipeline_run_id, trigger = nil)
      run = BeveragePipelineRun.find_by(id: pipeline_run_id)
      return unless run

      run.update!(
        current_step: 'publish',
        status: 'succeeded',
        completed_at: Time.current,
      )
    rescue StandardError => e
      run.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}") if run
      raise
    end
end
