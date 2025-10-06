require 'rails_helper'

RSpec.describe "onboarding/show.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:onboarding_session) { create(:onboarding_session, user: user, status: 'started') }

  before do
    assign(:current_user, user)
    assign(:onboarding_session, onboarding_session)
    assign(:step, 1)
    assign(:progress, 25)
    assign(:step_title, 'Account Details')
  end

  it 'renders the onboarding show page' do
    render
    expect(rendered).to include('Smart Menu Setup')
  end

  it 'displays progress information' do
    render
    expect(rendered).to include('Progress')
    expect(rendered).to include('25%')
  end

  it 'shows step indicators' do
    render
    expect(rendered).to include('Account Details')
    expect(rendered).to include('Restaurant Info')
    expect(rendered).to include('Choose Plan')
    expect(rendered).to include('Create Menu')
  end

  it 'includes wizard content area' do
    render
    expect(rendered).to include('wizard-content')
  end

  it 'includes testimonial section' do
    render
    expect(rendered).to include('Set up our digital menu in under 5 minutes!')
    expect(rendered).to include('Maria, Italian Bistro')
  end

  it 'renders without errors' do
    expect { render }.not_to raise_error
  end
end
