require 'rails_helper'

RSpec.describe "onboarding/update.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:onboarding_session) { create(:onboarding_session, user: user, status: 'restaurant_details') }

  before do
    assign(:current_user, user)
    assign(:onboarding_session, onboarding_session)
    assign(:step, 2)
    assign(:progress, 50)
    assign(:step_title, 'Restaurant Details')
  end

  it 'renders the onboarding update page' do
    render
    expect(rendered).to be_present
  end

  it 'displays update confirmation or redirect content' do
    render
    # The update.html.erb is likely a simple redirect or confirmation page
    expect(rendered).to match(/redirect|success|complete|update/i)
  end

  it 'renders without errors' do
    expect { render }.not_to raise_error
  end
end
