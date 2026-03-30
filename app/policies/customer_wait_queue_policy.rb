# frozen_string_literal: true

# Policy for CustomerWaitQueue.
# Only restaurant owners and active employees may manage the wait queue.
# Customers are never permitted to read or modify queue entries via the staff dashboard.
class CustomerWaitQueuePolicy < ApplicationPolicy
  # record is a CustomerWaitQueue instance; record.restaurant is the tenant.
  def index?
    staff_or_owner?
  end

  def show?
    staff_or_owner?
  end

  def create?
    staff_or_owner?
  end

  def update?
    staff_or_owner?
  end

  def seat?
    staff_or_owner?
  end

  def notify_customer?
    staff_or_owner?
  end

  def no_show?
    staff_or_owner?
  end

  def cancel?
    staff_or_owner?
  end

  def destroy?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.joins(:restaurant).where(restaurants: { user_id: user.id })
    end
  end

  private

  def staff_or_owner?
    return false unless user.present? && user.persisted?

    owner? || active_employee?
  end

  def owner?
    return false unless record.respond_to?(:restaurant)

    record.restaurant&.user_id == user.id
  end

  def active_employee?
    return false unless record.respond_to?(:restaurant)

    user.active_employee_for_restaurant?(record.restaurant_id)
  end
end
