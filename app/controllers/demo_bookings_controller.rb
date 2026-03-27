# frozen_string_literal: true

# Public-facing controller for demo booking submissions and video analytics.
# No Pundit authorisation required — this controller is entirely public.
# Rate-limited via Rack::Attack (demo_bookings/ip throttle in rack_attack.rb).
class DemoBookingsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_employee, raise: false
  skip_before_action :set_permissions, raise: false
  skip_before_action :redirect_to_onboarding_if_needed, raise: false

  # POST /demo_bookings
  # Accepts JSON. Returns the Calendly booking URL on success.
  def create
    @demo_booking = DemoBooking.new(demo_booking_params)

    if @demo_booking.save
      DemoBookingMailer.confirmation(@demo_booking).deliver_later
      render json: {
        ok: true,
        calendly_url: @demo_booking.calendly_booking_url,
        message: 'Thank you! Check your email for next steps.',
      }, status: :created
    else
      render json: {
        ok: false,
        errors: @demo_booking.errors.full_messages,
      }, status: :unprocessable_content
    end
  end

  # POST /demo_bookings/video_analytics
  # Logs a single video engagement event. Silently ignores unknown event types
  # so that clients with stale JS do not error-loop.
  def video_analytics
    event = VideoAnalytic.new(
      video_id: params[:video_id].to_s.truncate(255),
      session_id: params[:session_id].to_s.truncate(255),
      event_type: params[:event_type].to_s,
      timestamp_seconds: params[:timestamp_seconds].to_i,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s.truncate(1000),
      referrer: request.referer.to_s.truncate(500),
    )

    if event.valid?
      event.save!
      render json: { ok: true }, status: :created
    else
      # Unknown event types — acknowledge without creating a record
      render json: { ok: false, errors: event.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def demo_booking_params
    params.require(:demo_booking).permit(
      :restaurant_name,
      :contact_name,
      :email,
      :phone,
      :restaurant_type,
      :location_count,
      :interests,
    )
  end
end
