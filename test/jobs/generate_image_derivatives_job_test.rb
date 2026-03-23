# frozen_string_literal: true

require 'test_helper'

class GenerateImageDerivativesJobTest < ActiveSupport::TestCase
  def setup
    @job = GenerateImageDerivativesJob.new
  end

  test 'does not raise when record does not exist' do
    assert_nothing_raised do
      @job.perform('Menuitem', -999_999)
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      GenerateImageDerivativesJob.perform_later('Menuitem', -999_999)
    end
  end
end
