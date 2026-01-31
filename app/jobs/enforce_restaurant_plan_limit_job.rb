class EnforceRestaurantPlanLimitJob < ApplicationJob
  queue_as :default

  def perform(user_id: nil)
    if user_id.present?
      user = User.find_by(id: user_id)
      enforce_for_user(user) if user
      return
    end

    User.find_each do |user|
      enforce_for_user(user)
    end
  end

  private

  def enforce_for_user(user)
    plan = user.plan
    return unless plan
    return if plan.locations == -1

    limit = plan.locations.to_i
    return if limit <= 0

    active_scope = user.restaurants.where(archived: false, status: Restaurant.statuses[:active])
    active_count = active_scope.count
    return if active_count <= limit

    keep_ids = active_scope.order(created_at: :desc, id: :desc).limit(limit).pluck(:id)

    Restaurant.on_primary do
      Restaurant
        .where(user_id: user.id, archived: false, status: Restaurant.statuses[:active])
        .where.not(id: keep_ids)
        .update_all(status: Restaurant.statuses[:inactive], updated_at: Time.current)
    end
  end
end
