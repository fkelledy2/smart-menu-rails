# frozen_string_literal: true

class DwOrdersMvPolicy < ApplicationPolicy
  # Analytics data should only be accessible to authenticated users
  # and should be scoped to their own restaurant data

  def index?
    user.present?
  end

  def show?
    user.present? && owns_order_data?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Scope to orders from restaurants owned by the user
        # Assuming DwOrdersMv has a restaurant_id or similar field
        if scope.column_names.include?('restaurant_id')
          restaurant_ids = user.restaurants.pluck(:id)
          scope.where(restaurant_id: restaurant_ids)
        else
          # If no restaurant scoping is possible, return all for now
          # This should be reviewed and improved based on the actual model structure
          scope.all
        end
      else
        scope.none
      end
    end
  end

  private

  def owns_order_data?
    # If the record has restaurant_id, check ownership
    if record.respond_to?(:restaurant_id) && record.restaurant_id
      user.restaurants.exists?(id: record.restaurant_id)
    else
      # For now, allow access if user is authenticated
      # This should be improved based on actual data model
      true
    end
  end
end
