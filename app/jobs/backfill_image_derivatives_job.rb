# frozen_string_literal: true

# Regenerates all Shrine image derivatives for a single record.
# Used by the rake task to backfill WebP + card_webp derivatives
# for images uploaded before those derivatives were defined.
class BackfillImageDerivativesJob < ApplicationJob
  queue_as :low_priority

  # Sidekiq options: retry up to 2 times, don't clog the queue
  sidekiq_options retry: 2 if respond_to?(:sidekiq_options)

  def perform(record_class, record_id)
    klass = record_class.constantize
    record = klass.find_by(id: record_id)
    return unless record

    attacher = record.image_attacher
    return unless attacher.file # no image attached

    # Regenerate all derivatives from the original file
    attacher.create_derivatives(force: true)
    attacher.atomic_persist

    Rails.logger.info "[BackfillImageDerivatives] Regenerated derivatives for #{record_class}##{record_id}"
  rescue Shrine::AttachmentChanged
    Rails.logger.info "[BackfillImageDerivatives] Attachment changed for #{record_class}##{record_id}, skipping"
  rescue Shrine::FileNotFound, Aws::S3::Errors::NoSuchKey => e
    Rails.logger.warn "[BackfillImageDerivatives] Original file missing for #{record_class}##{record_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[BackfillImageDerivatives] Error for #{record_class}##{record_id}: #{e.class}: #{e.message}"
    raise # re-raise so Sidekiq retries
  end
end
