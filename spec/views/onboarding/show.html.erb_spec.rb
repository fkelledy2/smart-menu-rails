require 'rails_helper'

RSpec.describe 'onboarding/account_details.html.erb' do
  let(:user) { create(:user) }
  let(:onboarding_session) { create(:onboarding_session, user: user, status: 'started') }

  before do
    assign(:onboarding, onboarding_session)
    # The template uses current_user from the controller, stub via helper
    # Provide route helpers
    allow(view).to receive_messages(current_user: user, onboarding_path: '/onboarding')
  end

  it 'renders without errors' do
    expect { render }.not_to raise_error
  end

  it 'renders the account details form' do
    render
    expect(rendered).to include('wizard-form')
  end

  it 'includes a name field' do
    render
    expect(rendered).to have_field('user[name]')
  end

  it 'includes a restaurant name field' do
    render
    expect(rendered).to have_field('onboarding_session[restaurant_name]')
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_css('#continue-btn')
  end
end
