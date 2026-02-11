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
    return if user.super_admin?

    plan = user.plan
    return unless plan
    return if plan.locations == -1

    limit = plan.locations.to_i
    return if limit <= 0

    Restaurant.on_primary do
      # Treat archived NULL as not archived (older data / fixtures may not populate it).
      base_scope = Restaurant
        .where(user_id: user.id, status: Restaurant.statuses[:active])
        .where('archived IS NULL OR archived = ?', false)

      active_count = base_scope.count
      return if active_count <= limit

      keep_ids = base_scope.order(created_at: :desc, id: :desc).limit(limit).pluck(:id)

      base_scope
        .where.not(id: keep_ids)
        .update_all(status: Restaurant.statuses[:inactive], updated_at: Time.current)
    end
  end
end
