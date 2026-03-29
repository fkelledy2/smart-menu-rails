# frozen_string_literal: true

module Admin
  # Internal CRM view for demo leads. Supports CSV export.
  # Access restricted to @mellow.menu email addresses.
  class DemoBookingsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_mellow_admin!

    def index
      @demo_bookings = DemoBooking.recent

      respond_to do |format|
        format.html
        format.csv do
          send_data csv_export(@demo_bookings),
                    filename: "demo-bookings-#{Date.current.iso8601}.csv",
                    type: 'text/csv; charset=utf-8'
        end
      end
    end

    def show
      @demo_booking = DemoBooking.find(params[:id])
    end

    def update
      @demo_booking = DemoBooking.find(params[:id])

      if @demo_booking.update(update_params)
        redirect_to admin_demo_booking_path(@demo_booking), notice: 'Lead updated.'
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def update_params
      params.require(:demo_booking).permit(:conversion_status, :calendly_event_id)
    end

    def require_mellow_admin!
      return if current_user&.super_admin? && current_user&.email.to_s.end_with?('@mellow.menu')

      redirect_to root_path, alert: 'Access denied. mellow.menu staff only.', status: :see_other
    end

    def csv_export(bookings)
      require 'csv'
      CSV.generate(headers: true) do |csv|
        csv << %w[ID Restaurant Contact Email Phone VenueType Locations Interests CalendlyEventID Status CreatedAt]
        bookings.each do |b|
          csv << [
            b.id,
            b.restaurant_name,
            b.contact_name,
            b.email,
            b.phone,
            b.restaurant_type,
            b.location_count,
            b.interests,
            b.calendly_event_id,
            b.conversion_status,
            b.created_at.iso8601,
          ]
        end
      end
    end
  end
end
