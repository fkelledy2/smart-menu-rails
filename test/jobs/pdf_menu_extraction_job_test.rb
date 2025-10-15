require 'test_helper'

class PdfMenuExtractionJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @restaurant = restaurants(:one)
  end

  test 'performs successfully and completes the import on processor success' do
    import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Job Import', status: :pending)

    # Stub PdfMenuProcessor to simulate success
    processor_double = Minitest::Mock.new
    processor_double.expect :process, true

    PdfMenuProcessor.stub :new, processor_double do
      # Perform the job directly instead of using assert_enqueued_with
      PdfMenuExtractionJob.perform_now(import.id)
    end

    import.reload
    assert_equal 'completed', import.status
    assert_not_nil import.completed_at
  end

  test 'fails the import and records error on processor failure' do
    import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Job Import Fail', status: :pending)

    # Stub PdfMenuProcessor to simulate failure
    processor_double = Minitest::Mock.new
    processor_double.expect :process, false

    PdfMenuProcessor.stub :new, processor_double do
      # Perform the job directly instead of using perform_enqueued_jobs
      PdfMenuExtractionJob.perform_now(import.id)
    end

    import.reload
    assert_equal 'failed', import.status
    assert_not_nil import.failed_at
    assert import.error_message.present?
  end

  test 'does nothing when already completed' do
    import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Already Done', status: :completed)

    # Should not call processor at all; stub to raise if called
    PdfMenuProcessor.stub :new, ->(*) { raise 'should not be called' } do
      perform_enqueued_jobs do
        PdfMenuExtractionJob.perform_later(import.id)
      end
    end

    assert_equal 'completed', import.reload.status
  end
end
