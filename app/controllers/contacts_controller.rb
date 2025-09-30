class ContactsController < ApplicationController
  # Public contact form - no authentication required
  after_action :verify_authorized

  def new
    @contact = Contact.new
    authorize @contact
    
    # Track contact form view
    anonymous_id = session[:session_id] ||= SecureRandom.uuid
    AnalyticsService.track_anonymous_event(anonymous_id, 'contact_form_viewed', {
      referrer: request.referer,
      user_type: current_user ? 'authenticated' : 'anonymous'
    })
  end

  def create
    @contact = Contact.new(contact_params)
    authorize @contact
    if @contact.save
      ContactMailer.receipt(@contact).deliver_now
      ContactMailer.notification(@contact).deliver_now
      
      # Track successful contact form submission
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_anonymous_event(anonymous_id, 'contact_form_submitted', {
        email_domain: @contact.email.split('@').last,
        message_length: @contact.message.length,
        user_type: current_user ? 'authenticated' : 'anonymous'
      })
      
      flash[:notice] = t('contacts.controller.thanks')
      redirect_to root_url
    else
      # Track failed contact form submission
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_anonymous_event(anonymous_id, 'contact_form_failed', {
        errors: @contact.errors.full_messages,
        user_type: current_user ? 'authenticated' : 'anonymous'
      })
      
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:email, :message)
  end
end
