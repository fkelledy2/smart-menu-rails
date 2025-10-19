# Controller for managing push notification subscriptions
class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:destroy]
  
  # POST /push_subscriptions
  def create
    @subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )
    
    @subscription.assign_attributes(subscription_params)
    @subscription.active = true
    
    if @subscription.save
      render json: { 
        success: true, 
        message: 'Push notifications enabled',
        subscription_id: @subscription.id
      }, status: :created
    else
      render json: { 
        success: false, 
        errors: @subscription.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # DELETE /push_subscriptions/:id
  def destroy
    if @subscription.destroy
      render json: { 
        success: true, 
        message: 'Push notifications disabled' 
      }
    else
      render json: { 
        success: false, 
        errors: @subscription.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end
  
  # POST /push_subscriptions/test
  def test
    count = PushNotificationService.send_test_notification(current_user)
    
    if count > 0
      render json: { 
        success: true, 
        message: "Test notification sent to #{count} device(s)" 
      }
    else
      render json: { 
        success: false, 
        message: 'No active push subscriptions found' 
      }, status: :not_found
    end
  end
  
  private
  
  def set_subscription
    @subscription = current_user.push_subscriptions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      success: false, 
      error: 'Subscription not found' 
    }, status: :not_found
  end
  
  def subscription_params
    params.require(:subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
