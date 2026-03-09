require 'rails_helper'

RSpec.describe 'kitchen_dashboard/index.html.erb', type: :view do
  it 'renders the metrics and empty states' do
    assign(:restaurant, build_stubbed(:restaurant, id: 123))
    assign(:metrics, { total_pending: 2, total_preparing: 3, total_ready: 1, orders_today: 7 })
    assign(:pending_tickets, [])
    assign(:preparing_tickets, [])
    assign(:ready_tickets, [])

    render

    expect(rendered).to include('Pending Tickets')
    expect(rendered).to include('Preparing')
    expect(rendered).to include('Ready')
    expect(rendered).to include("Today's Orders")
    expect(rendered).to include('0 pending tickets')
    expect(rendered).to include('0 preparing tickets')
    expect(rendered).to include('0 ready tickets')
    expect(rendered).to include('data-restaurant-id="123"')
  end
end
