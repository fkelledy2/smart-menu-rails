# frozen_string_literal: true

# Shows 2FA adoption statistics across restaurants and users.
class Admin::TwoFactorReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_super_admin!
  after_action :verify_authorized

  def index
    authorize :two_factor_report, :index?, policy_class: Admin::TwoFactorReportPolicy

    @total_users = User.count
    @enabled_users = User.where(otp_enabled: true).count
    @adoption_rate = @total_users.positive? ? (@enabled_users.to_f / @total_users * 100).round(1) : 0

    # Admin-role employees
    admin_employee_user_ids = Employee.active.admin.distinct.pluck(:user_id)
    @admin_user_count = admin_employee_user_ids.size
    @admin_users_with_2fa = User.where(id: admin_employee_user_ids, otp_enabled: true).count
    @admin_adoption_rate = @admin_user_count.positive? ? (@admin_users_with_2fa.to_f / @admin_user_count * 100).round(1) : 0

    # Per-restaurant breakdown (top 20 by user count)
    @restaurant_stats = Restaurant
      .joins('LEFT JOIN employees ON employees.restaurant_id = restaurants.id AND employees.status = 1')
      .joins('LEFT JOIN users ON users.id = employees.user_id')
      .select(
        'restaurants.id',
        'restaurants.name',
        'COUNT(DISTINCT employees.user_id) AS employee_count',
        'COUNT(DISTINCT CASE WHEN users.otp_enabled = TRUE THEN users.id END) AS enabled_count',
      )
      .group('restaurants.id, restaurants.name')
      .order('employee_count DESC')
      .limit(20)
  end

  private

  def ensure_super_admin!
    redirect_to root_path, alert: 'Not authorised' unless current_user&.super_admin?
  end
end
