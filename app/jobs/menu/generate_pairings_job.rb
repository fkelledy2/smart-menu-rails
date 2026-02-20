# frozen_string_literal: true

class Menu::GeneratePairingsJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  def perform(pipeline_run_id, trigger = nil)
    run = BeveragePipelineRun.find_by(id: pipeline_run_id)
    return unless run

    run.update!(current_step: 'generate_pairings')

    menu = run.menu
    engine = BeverageIntelligence::PairingEngine.new
    pairings_count = engine.generate_for_menu(menu)

    Rails.logger.info("[GeneratePairingsJob] Generated #{pairings_count} pairings for menu ##{menu.id}")

    Menu::GenerateRecsJob.perform_async(run.id, trigger)
  rescue StandardError => e
    run&.update!(status: 'failed', error_summary: "#{e.class}: #{e.message}")
    Rails.logger.error("[GeneratePairingsJob] Failed: #{e.class}: #{e.message}")
    raise
  end
end
