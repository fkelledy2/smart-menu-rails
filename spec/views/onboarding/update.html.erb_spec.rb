require 'rails_helper'

# The update action re-renders account_details on validation failure
# or redirects on success — there is no update.html.erb template.
RSpec.describe 'onboarding/account_details.html.erb (re-render on update failure)' do
  let(:user) { create(:user) }
  let(:onboarding_session) { create(:onboarding_session, user: user, status: 'started') }

  before do
    assign(:onboarding, onboarding_session)
    allow(view).to receive_messages(current_user: user, onboarding_path: '/onboarding')
    flash.now[:alert] = 'Please enter a restaurant name to continue.'
  end

  it 're-renders the account details form' do
    render template: 'onboarding/account_details'
    expect(rendered).to include('wizard-form')
  end

  it 'renders without errors' do
    expect { render template: 'onboarding/account_details' }.not_to raise_error
  end
end
