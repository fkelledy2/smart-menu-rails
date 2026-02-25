require 'rails_helper'

RSpec.describe OnboardingHelper do
  # Onboarding is now a single step (account details + restaurant name).
  # The go-live checklist on the restaurant edit page is the canonical
  # onboarding experience after the initial step.
  #
  # Legacy multi-step helpers (step_title, progress_percentage,
  # step_completed?, next_step) were removed — they referenced a
  # 4-step wizard that no longer exists.

  it 'is an empty module (legacy multi-step helpers were removed)' do
    # The module exists but defines no public instance methods
    own_methods = described_class.instance_methods(false)
    expect(own_methods).to be_empty
  end

  it 'can be included in a helper context' do
    expect(helper).to be_a(described_class)
  end
end
