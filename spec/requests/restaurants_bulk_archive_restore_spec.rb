require 'rails_helper'

RSpec.describe 'Restaurants bulk archive/restore' do
  let(:user) { create(:user) }
  let!(:restaurant1) { create(:restaurant, user: user, status: 'active', archived: false) }
  let!(:restaurant2) { create(:restaurant, user: user, status: 'active', archived: false) }

  before do
    sign_in user
  end

  describe 'PATCH /restaurants/bulk_update' do
    it 'enqueues archive jobs for selected restaurants' do
      expect(RestaurantArchiveJob).to receive(:perform_async).with(restaurant1.id, user.id, nil)
      expect(RestaurantArchiveJob).to receive(:perform_async).with(restaurant2.id, user.id, nil)

      patch bulk_update_restaurants_path, params: {
        restaurant_ids: [restaurant1.id, restaurant2.id],
        operation: 'archive',
        value: '1',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end

    it 'enqueues restore jobs for selected restaurants' do
      expect(RestaurantRestoreJob).to receive(:perform_async).with(restaurant1.id, user.id, nil)
      expect(RestaurantRestoreJob).to receive(:perform_async).with(restaurant2.id, user.id, nil)

      patch bulk_update_restaurants_path, params: {
        restaurant_ids: [restaurant1.id, restaurant2.id],
        operation: 'restore',
        value: '1',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end
  end
end
