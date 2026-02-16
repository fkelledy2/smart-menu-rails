# app/jobs/generate_image_derivatives_job.rb
class GenerateImageDerivativesJob < ApplicationJob
  queue_as :default

  def perform(record_class, record_id)
    record = record_class.constantize.find(record_id)
    attacher = record.image_attacher
    attacher.create_derivatives(force: true)
    attacher.atomic_persist
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[GenerateImageDerivativesJob] Record not found: #{record_class}##{record_id}"
  rescue Shrine::AttachmentChanged
    Rails.logger.info "[GenerateImageDerivativesJob] Attachment changed for #{record_class}##{record_id}, skipping"
  end
end
