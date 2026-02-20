# frozen_string_literal: true

class Menu::GenerateRecsJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(pipeline_run_id, trigger = nil)
    run = BeveragePipelineRun.find_by(id: pipeline_run_id)
    return unless run

    run.update!(current_step: 'generate_recs')

    menu = run.menu
    recommender = BeverageIntelligence::Recommender.new
    recs_count = recommender.generate_for_menu(menu)

    Rails.logger.info("[GenerateRecsJob] Generated #{recs_count} similarity recs for menu ##{menu.id}")

    Menu::PublishSommelierJob.perform_async(run.id, trigger)
  rescue StandardError => e
    run&.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}")
    Rails.logger.error("[GenerateRecsJob] Failed: #{e.class}: #{e.message}")
    raise
  end
end
