# Enhanced AdvancedCacheService that can return both Hash data and model instances
# This provides backward compatibility while adding model instance support
class AdvancedCacheServiceV2 < AdvancedCacheService
  class << self
    # Enhanced method that can return either cached hash data or model instances
    def cached_restaurant_orders_with_models(restaurant_id, include_calculations: false, return_models: true)
      # Get cached hash data (for performance and calculations)
      cached_data = cached_restaurant_orders(restaurant_id, include_calculations: include_calculations)

      return cached_data unless return_models

      # Extract IDs and fetch model instances
      order_ids = cached_data[:orders].pluck(:id)
      restaurant = Restaurant.find(restaurant_id)
      orders = restaurant.ordrs.where(id: order_ids)
        .includes(:ordritems, :tablesetting, :menu, :employee)
        .order(created_at: :desc)

      # Return enhanced structure with both cached data and models
      {
        restaurant: restaurant, # Model instance
        orders: orders, # ActiveRecord relation
        cached_calculations: cached_data[:orders], # Hash data with calculations
        metadata: cached_data[:metadata],
      }
    end

    # Enhanced method for user orders
    def cached_user_all_orders_with_models(user_id, return_models: true)
      cached_data = cached_user_all_orders(user_id)

      return cached_data unless return_models

      # Extract IDs and fetch model instances
      order_ids = cached_data[:orders].pluck(:id)
      user = User.find(user_id)
      orders = Ordr.joins(restaurant: :user)
        .where(id: order_ids, restaurant: { user: user })
        .includes(:ordritems, :tablesetting, :menu, :restaurant)
        .order(created_at: :desc)

      {
        user: user, # Model instance
        orders: orders, # ActiveRecord relation
        cached_data: cached_data[:orders], # Hash data
        metadata: cached_data[:metadata],
      }
    end

    # Enhanced method for employees
    def cached_restaurant_employees_with_models(restaurant_id, include_analytics: false, return_models: true)
      cached_data = cached_restaurant_employees(restaurant_id, include_analytics: include_analytics)

      return cached_data unless return_models

      # Extract IDs and fetch model instances
      employee_ids = cached_data[:employees].pluck(:id)
      restaurant = Restaurant.find(restaurant_id)
      employees = restaurant.employees.where(id: employee_ids)
        .where.not(status: :archived)
        .includes(:user)
        .order(:sequence)

      {
        restaurant: restaurant, # Model instance
        employees: employees, # ActiveRecord relation
        cached_analytics: cached_data[:employees], # Hash data with analytics
        metadata: cached_data[:metadata],
      }
    end

    # Generic method to convert any cached collection to models
    def cached_collection_to_models(cached_data, model_class, scope_proc = nil)
      return cached_data unless (cached_data.is_a?(Hash) && cached_data.key?(:orders)) || cached_data.key?(:employees)

      collection_key = cached_data.key?(:orders) ? :orders : :employees
      ids = cached_data[collection_key].pluck(:id)

      base_scope = model_class.where(id: ids)
      base_scope = scope_proc.call(base_scope) if scope_proc

      cached_data.merge(collection_key => base_scope)
    end
  end
end
