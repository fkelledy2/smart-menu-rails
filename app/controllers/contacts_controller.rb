class ContactsController < ApplicationController
  # Public contact form - no authentication required
  after_action :verify_authorized

  def new
    @contact = Contact.new
    authorize @contact
  end

  def create
    @contact = Contact.new(contact_params)
    authorize @contact
    if @contact.save
      ContactMailer.receipt(@contact).deliver_now
      ContactMailer.notification(@contact).deliver_now
      flash[:notice] = t('contacts.controller.thanks')
      redirect_to root_url
    else
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:email, :message)
  end
end
