require 'rails_helper'

RSpec.describe 'onboarding/account_details.html.erb' do
  let(:user) { create(:user) }
  let(:onboarding_session) { create(:onboarding_session, user: user, status: 'started') }

  before do
    assign(:onboarding, onboarding_session)
    # The template uses current_user from the controller, stub via helper
    allow(view).to receive(:current_user).and_return(user)
    # Provide route helpers
    allow(view).to receive(:onboarding_path).and_return('/onboarding')
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
    expect(rendered).to have_selector('input[name="user[name]"]')
  end

  it 'includes a restaurant name field' do
    render
    expect(rendered).to have_selector('input[name="onboarding_session[restaurant_name]"]')
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_selector('#continue-btn')
  end
end
