class Menu::BeveragePipelineStartJob
  include Sidekiq::Job

    sidekiq_options queue: 'default', retry: 3

    def perform(menu_id, restaurant_id, trigger = nil)
      menu = ::Menu.find_by(id: menu_id)
      restaurant = ::Restaurant.find_by(id: restaurant_id)
      return unless menu && restaurant

      existing = BeveragePipelineRun.where(menu_id: menu.id, status: 'running').order(created_at: :desc).first
      return if existing

      run = BeveragePipelineRun.create!(
        menu: menu,
        restaurant: restaurant,
        status: 'running',
        current_step: 'start',
        started_at: Time.current,
      )

      Menu::ExtractCandidatesJob.perform_async(run.id, trigger)
    rescue StandardError => e
      Rails.logger.error("[BeveragePipelineStartJob] Failed to start pipeline for menu ##{menu_id}: #{e.class}: #{e.message}")
      raise
    end
end
