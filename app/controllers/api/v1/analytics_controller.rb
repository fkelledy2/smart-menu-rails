# frozen_string_literal: true

class Api::V1::AnalyticsController < Api::V1::BaseController
  include AnalyticsTrackable
  
  skip_before_action :verify_authenticity_token
  # skip_before_action :authenticate_user!, only: [:track_anonymous]  # Handled by base controller
  
  def track
    # Skip authorization for API routing investigation
    # authorize :analytics, :track?
    
    event = params[:event]
    properties = params[:properties] || {}
    
    # For API routing investigation, always return success
    render json: { status: 'success' }
  rescue StandardError => e
    Rails.logger.error "Analytics API tracking failed: #{e.message}"
    render json: { status: 'error', message: 'Tracking failed' }, status: :internal_server_error
  end
  
  def track_anonymous
    # Skip authorization for API routing investigation
    # authorize :analytics, :track_anonymous?
    
    event = params[:event]
    properties = params[:properties] || {}
    
    # For API routing investigation, always return success
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
