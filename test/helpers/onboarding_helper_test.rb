require 'test_helper'

class OnboardingHelperTest < ActionView::TestCase
  # OnboardingHelper is now empty — the multi-step wizard helpers
  # (step_title, progress_percentage, step_completed?, next_step)
  # were removed when onboarding was simplified to a single step.
  #
  # The go-live checklist on the restaurant edit page is now
  # the canonical onboarding experience after initial sign-up.

  test 'module exists and is includable' do
    assert_kind_of Module, OnboardingHelper
  end
end
