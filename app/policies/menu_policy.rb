class MenuPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # Allow public access for customer viewing, but restrict sensitive data to owners
    return true unless user # Allow anonymous customers
    
    owner?
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def regenerate_images?
    owner?
  end

  def analytics?
    owner?
  end

  def performance?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def owner?
    return false unless user && record.respond_to?(:restaurant)

    record.restaurant.user_id == user.id
  end
end
