require 'rails_helper'

RSpec.describe 'Restaurants bulk archive/restore' do
  let(:user) { create(:user) }
  let!(:primary_restaurant) { create(:restaurant, user: user, status: 'active', archived: false) }
  let!(:secondary_restaurant) { create(:restaurant, user: user, status: 'active', archived: false) }

  before do
    sign_in user
  end

  describe 'PATCH /restaurants/bulk_update' do
    it 'enqueues archive jobs for selected restaurants' do
      allow(RestaurantArchiveJob).to receive(:perform_async)

      patch bulk_update_restaurants_path, params: {
        restaurant_ids: [primary_restaurant.id, secondary_restaurant.id],
        operation: 'archive',
        value: '1',
      }

      expect(RestaurantArchiveJob).to have_received(:perform_async).with(primary_restaurant.id, user.id, nil)
      expect(RestaurantArchiveJob).to have_received(:perform_async).with(secondary_restaurant.id, user.id, nil)
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end

    it 'enqueues restore jobs for selected restaurants' do
      allow(RestaurantRestoreJob).to receive(:perform_async)

      patch bulk_update_restaurants_path, params: {
        restaurant_ids: [primary_restaurant.id, secondary_restaurant.id],
        operation: 'restore',
        value: '1',
      }

      expect(RestaurantRestoreJob).to have_received(:perform_async).with(primary_restaurant.id, user.id, nil)
      expect(RestaurantRestoreJob).to have_received(:perform_async).with(secondary_restaurant.id, user.id, nil)
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end
  end
end
