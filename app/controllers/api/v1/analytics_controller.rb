# frozen_string_literal: true

class Api::V1::AnalyticsController < Api::V1::BaseController
  include AnalyticsTrackable
  
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!, except: [:track_anonymous]
  
  def track
    event = params[:event]
    properties = params[:properties] || {}
    
    if user_signed_in?
      AnalyticsService.track_user_event(current_user, event, properties)
      render json: { status: 'success' }
    else
      render json: { status: 'error', message: 'User not authenticated' }, status: :unauthorized
    end
  rescue StandardError => e
    Rails.logger.error "Analytics API tracking failed: #{e.message}"
    render json: { status: 'error', message: 'Tracking failed' }, status: :internal_server_error
  end
  
  def track_anonymous
    event = params[:event]
    properties = params[:properties] || {}
    anonymous_id = session[:session_id] ||= SecureRandom.uuid
    
    AnalyticsService.track_anonymous_event(anonymous_id, event, properties)
    render json: { status: 'success' }
  rescue StandardError => e
    Rails.logger.error "Anonymous analytics API tracking failed: #{e.message}"
    render json: { status: 'error', message: 'Tracking failed' }, status: :internal_server_error
  end
  
  private
  
  # Override to skip page tracking for API endpoints
  def should_track_page_view?
    false
  end
end
