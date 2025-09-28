# app/jobs/generate_image_derivatives_job.rb
class GenerateImageDerivativesJob < ApplicationJob
  queue_as :default

  def perform(record_class, record_id)
    record = record_class.constantize.find(record_id)
    attacher = record.image_attacher
    attacher.create_derivatives(only: %i[thumb large], force: true)
    attacher.atomic_persist
  end
end
