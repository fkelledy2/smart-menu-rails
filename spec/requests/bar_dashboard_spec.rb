require 'rails_helper'

RSpec.describe 'BarDashboards' do
  describe 'GET /restaurants/:id/bar' do
    let(:owner) { create(:user) }
    let(:restaurant) { create(:restaurant, user: owner) }

    it 'redirects when not signed in' do
      get "/restaurants/#{restaurant.id}/bar"
      expect(response).not_to have_http_status(:success)
    end

    it 'allows the restaurant owner' do
      sign_in owner

      get "/restaurants/#{restaurant.id}/bar"
      expect(response).to have_http_status(:success)
    end

    it 'allows an active employee (staff)' do
      employee_user = create(:user)
      create(:employee, user: employee_user, restaurant: restaurant, status: 'active', role: 'staff')
      sign_in employee_user

      get "/restaurants/#{restaurant.id}/bar"
      expect(response).to have_http_status(:success)
    end

    it 'denies a user who is not owner or employee' do
      other_user = create(:user)
      sign_in other_user

      get "/restaurants/#{restaurant.id}/bar"
      expect(response).not_to have_http_status(:success)
    end
  end

  describe 'PATCH /restaurants/:restaurant_id/ordr_station_tickets/:id' do
    it 'allows an active employee to update ticket status' do
      owner = create(:user)
      restaurant = create(:restaurant, user: owner)

      employee_user = create(:user)
      create(:employee, user: employee_user, restaurant: restaurant, status: 'active', role: 'staff')

      menu = create(:menu, restaurant: restaurant, owner_restaurant: restaurant)
      ordr = create(:ordr, menu: menu)

      ticket = OrdrStationTicket.create!(
        restaurant: restaurant,
        ordr: ordr,
        station: :bar,
        status: :ordered,
        sequence: 1,
        submitted_at: Time.current,
      )

      sign_in employee_user

      patch "/restaurants/#{restaurant.id}/ordr_station_tickets/#{ticket.id}",
            params: { ordr_station_ticket: { status: 'preparing' } },
            headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(ticket.reload.status).to eq('preparing')
    end

    it 'returns forbidden for a user who is not owner or employee' do
      owner = create(:user)
      restaurant = create(:restaurant, user: owner)

      other_user = create(:user)

      menu = create(:menu, restaurant: restaurant, owner_restaurant: restaurant)
      ordr = create(:ordr, menu: menu)

      ticket = OrdrStationTicket.create!(
        restaurant: restaurant,
        ordr: ordr,
        station: :bar,
        status: :ordered,
        sequence: 1,
        submitted_at: Time.current,
      )

      sign_in other_user

      patch "/restaurants/#{restaurant.id}/ordr_station_tickets/#{ticket.id}",
            params: { ordr_station_ticket: { status: 'preparing' } },
            headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      expect(ticket.reload.status).to eq('ordered')
    end

    it 'returns 422 for invalid status transition' do
      owner = create(:user)
      restaurant = create(:restaurant, user: owner)

      employee_user = create(:user)
      create(:employee, user: employee_user, restaurant: restaurant, status: 'active', role: 'staff')

      menu = create(:menu, restaurant: restaurant, owner_restaurant: restaurant)
      ordr = create(:ordr, menu: menu)

      ticket = OrdrStationTicket.create!(
        restaurant: restaurant,
        ordr: ordr,
        station: :bar,
        status: :ready,
        sequence: 1,
        submitted_at: Time.current,
      )

      sign_in employee_user

      patch "/restaurants/#{restaurant.id}/ordr_station_tickets/#{ticket.id}",
            params: { ordr_station_ticket: { status: 'preparing' } },
            headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ticket.reload.status).to eq('ready')
    end
  end
end
