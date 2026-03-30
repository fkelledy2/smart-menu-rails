# frozen_string_literal: true

class PushSubscriptionPolicy < ApplicationPolicy
  # Any authenticated user can manage their own push subscriptions.

  def create?
    user.persisted?
  end

  def destroy?
    user.persisted? && record.user_id == user.id
  end

  # test action — any authenticated user can send themselves a test notification
  def test?
    user.persisted?
  end
end
