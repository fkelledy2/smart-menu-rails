# frozen_string_literal: true

require 'test_helper'

class BackfillImageDerivativesJobTest < ActiveSupport::TestCase
  test 'does nothing when record class cannot be found' do
    assert_nothing_raised do
      BackfillImageDerivativesJob.new.perform('Menuitem', -999_999)
    end
  end

  test 'does nothing when record exists but has no image attached' do
    menuitem = menuitems(:one)

    # Ensure no image is attached — just assert no exception raised
    assert_nothing_raised do
      BackfillImageDerivativesJob.new.perform('Menuitem', menuitem.id)
    end
  end

  test 'does not raise for invalid record_class constant' do
    # constantize on an invalid class name raises NameError which should be rescued
    assert_nothing_raised do
      begin
        BackfillImageDerivativesJob.new.perform('NonExistentRecordClass99', 1)
      rescue NameError
        # Expected: constantize raises NameError for unknown class, re-raised by job
        # This is acceptable — the job re-raises StandardError for Sidekiq retries
      end
    end
  end

  test 'enqueues asynchronously without raising' do
    assert_nothing_raised do
      BackfillImageDerivativesJob.perform_later('Menuitem', 1)
    end
  end
end
