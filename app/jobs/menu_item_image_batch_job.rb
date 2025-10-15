class MenuItemImageBatchJob
  include Sidekiq::Job

  def perform(menu_id)
    Rails.logger.info "[MenuItemImageBatchJob] Starting image regeneration for menu_id=#{menu_id}"
    
    # Call the rake task logic directly
    scope = Genimage.where(menu_id: menu_id)
    total = scope.count
    
    Rails.logger.info "[MenuItemImageBatchJob] Processing #{total} genimages for menu_id=#{menu_id}"
    
    processed = 0
    scope.find_each.with_index do |genimage, index|
      Rails.logger.debug "[MenuItemImageBatchJob] Processing genimage ##{genimage.id} (#{index + 1}/#{total})"

      # Skip if the genimage is associated with a wine item
      if genimage.menuitem&.itemtype == 'wine'
        Rails.logger.debug "[MenuItemImageBatchJob] Skipping wine item for genimage ##{genimage.id}"
        next
      end

      # Process the image using the job (synchronously within this job)
      MenuItemImageGeneratorJob.perform_sync(genimage.id)
      processed += 1

      # Small delay to avoid rate limiting (only if not the last item)
      sleep(1) if index < total - 1
    rescue StandardError => e
      Rails.logger.error "[MenuItemImageBatchJob] Error processing genimage ##{genimage.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if e.backtrace
    end

    Rails.logger.info "[MenuItemImageBatchJob] Finished regenerating images for menu_id=#{menu_id}. Processed: #{processed}/#{total}"
  end
end
