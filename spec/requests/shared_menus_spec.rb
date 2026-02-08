require 'rails_helper'

RSpec.describe 'Shared menus' do
  let(:user) { create(:user) }
  let(:restaurant_a) { create(:restaurant, user: user) }
  let(:restaurant_b) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant_a, owner_restaurant: restaurant_a) }

  before do
    sign_in user

    RestaurantSubscription.create!(
      restaurant: restaurant_a,
      status: :active,
      payment_method_on_file: true,
    )

    RestaurantSubscription.create!(
      restaurant: restaurant_b,
      status: :active,
      payment_method_on_file: true,
    )

    RestaurantMenu.find_or_create_by!(restaurant: restaurant_a, menu: menu) do |rm|
      rm.status = 'active'
      rm.sequence = 1
    end
  end

  describe 'attaching and detaching menus' do
    it 'attaches a menu to another restaurant' do
      expect do
        post attach_restaurant_menu_path(restaurant_b, menu)
      end.to change { RestaurantMenu.where(restaurant: restaurant_b, menu: menu).count }.from(0).to(1)

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end

    it 'does not allow owner restaurant to detach its own menu' do
      expect do
        delete detach_restaurant_menu_path(restaurant_a, menu)
      end.not_to change { RestaurantMenu.where(restaurant: restaurant_a, menu: menu).count }
    end

    it 'detaches a menu from a restaurant' do
      create(:restaurant_menu, restaurant: restaurant_b, menu: menu, status: 'active', sequence: 1)

      expect do
        delete detach_restaurant_menu_path(restaurant_b, menu)
      end.to change { RestaurantMenu.where(restaurant: restaurant_b, menu: menu).count }.from(1).to(0)

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
    end

    it 'shares a menu to another restaurant' do
      expect do
        post share_restaurant_menu_path(restaurant_a, menu), params: { target_restaurant_id: restaurant_b.id }
      end.to change { RestaurantMenu.where(restaurant: restaurant_b, menu: menu).count }.from(0).to(1)
    end

    it 'shares a menu to multiple restaurants in one request' do
      restaurant_c = create(:restaurant, user: user)

      expect do
        post share_restaurant_menu_path(restaurant_a, menu), params: { target_restaurant_ids: [restaurant_b.id, restaurant_c.id] }
      end.to change { RestaurantMenu.where(menu: menu).count }.by(2)

      expect(RestaurantMenu.where(restaurant: restaurant_b, menu: menu).count).to eq(1)
      expect(RestaurantMenu.where(restaurant: restaurant_c, menu: menu).count).to eq(1)
    end

    it 'shares a menu to all other restaurants when all is selected' do
      restaurant_b
      restaurant_c = create(:restaurant, user: user)

      expect do
        post share_restaurant_menu_path(restaurant_a, menu), params: { target_restaurant_ids: ['all'] }
      end.to change { RestaurantMenu.where(menu: menu).count }.by(2)

      expect(RestaurantMenu.where(restaurant: restaurant_b, menu: menu).count).to eq(1)
      expect(RestaurantMenu.where(restaurant: restaurant_c, menu: menu).count).to eq(1)
    end

    it 'does not allow sharing to a restaurant not owned by the user' do
      other_user = create(:user)
      other_restaurant = create(:restaurant, user: other_user)

      expect do
        post share_restaurant_menu_path(restaurant_a, menu), params: { target_restaurant_id: other_restaurant.id }
      end.not_to change { RestaurantMenu.where(menu: menu).count }
    end

    it 'does not allow re-sharing a menu from a non-owner restaurant context' do
      restaurant_c = create(:restaurant, user: user)
      post attach_restaurant_menu_path(restaurant_b, menu)

      expect do
        post share_restaurant_menu_path(restaurant_b, menu), params: { target_restaurant_ids: [restaurant_c.id] }
      end.not_to change { RestaurantMenu.where(restaurant: restaurant_c, menu: menu).count }
    end
  end

  describe 'read-only enforcement in non-owner restaurant context' do
    before do
      post attach_restaurant_menu_path(restaurant_b, menu)
    end

    it 'allows viewing the menu edit page (read-only) from non-owner restaurant context' do
      get edit_restaurant_menu_path(restaurant_b, menu)
      expect(response).to have_http_status(:ok)
    end

    it 'does not allow updates from non-owner restaurant context' do
      patch restaurant_menu_path(restaurant_b, menu), params: { menu: { name: 'Changed' } }
      expect(response).to redirect_to(edit_restaurant_path(restaurant_b, section: 'menus'))
      expect(menu.reload.name).not_to eq('Changed')
    end

    it 'renders smartmenu show for the attached restaurant context (no redirect to root)' do
      smartmenu = Smartmenu.find_by!(restaurant: restaurant_b, menu: menu, tablesetting_id: nil)

      get "/smartmenus/#{smartmenu.slug}", params: { view: 'staff' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'availability override' do
    it 'updates availability on restaurant_menu' do
      post attach_restaurant_menu_path(restaurant_b, menu)
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)

      patch availability_restaurant_restaurant_menu_path(restaurant_b, rm), params: {
        availability_override_enabled: 'true',
        availability_state: 'unavailable',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(rm.reload.availability_override_enabled).to be(true)
      expect(rm.availability_state).to eq('unavailable')
    end
  end

  describe 'attachment ordering and bulk operations' do
    before do
      post attach_restaurant_menu_path(restaurant_b, menu)
    end

    it 'reorders restaurant_menus by updating sequence' do
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)

      patch reorder_restaurant_restaurant_menus_path(restaurant_b), params: {
        order: [{ id: rm.id, sequence: 2 }],
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(rm.reload.sequence).to eq(2)
    end

    it 'bulk updates status on restaurant_menus' do
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)

      patch bulk_update_restaurant_restaurant_menus_path(restaurant_b), params: {
        restaurant_menu_ids: [rm.id],
        operation: 'set_status',
        value: 'inactive',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(rm.reload.status).to eq('inactive')
    end

    it 'bulk archives restaurant_menus' do
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)

      patch bulk_update_restaurant_restaurant_menus_path(restaurant_b), params: {
        restaurant_menu_ids: [rm.id],
        operation: 'archive',
        value: '1',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(rm.reload.status).to eq('archived')
    end

    it 'bulk restores restaurant_menus' do
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)
      rm.update!(status: 'archived')

      patch bulk_update_restaurant_restaurant_menus_path(restaurant_b), params: {
        restaurant_menu_ids: [rm.id],
        operation: 'restore',
        value: '1',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(rm.reload.status).to eq('active')
    end

    it 'bulk updates availability override on restaurant_menus' do
      rm = RestaurantMenu.find_by!(restaurant: restaurant_b, menu: menu)

      patch bulk_availability_restaurant_restaurant_menus_path(restaurant_b), params: {
        restaurant_menu_ids: [rm.id],
        availability_override_enabled: 'true',
        availability_state: 'unavailable',
      }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      rm.reload
      expect(rm.availability_override_enabled).to be(true)
      expect(rm.availability_state).to eq('unavailable')
    end
  end

  describe 'policy scope' do
    it 'includes menus attached to an employee restaurant' do
      employee_user = create(:user)
      employee_restaurant = create(:restaurant, user: user)
      create(:employee, user: employee_user, restaurant: employee_restaurant, status: 'active', role: 'admin')

      menu2 = create(:menu, restaurant: restaurant_a, owner_restaurant: restaurant_a)
      create(:restaurant_menu, restaurant: employee_restaurant, menu: menu2, status: 'active', sequence: 1)

      scope = MenuPolicy::Scope.new(employee_user, Menu.all).resolve
      expect(scope).to include(menu2)
    end
  end
end
