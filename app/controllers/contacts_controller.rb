class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      ContactMailer.receipt(@contact).deliver_now
      ContactMailer.notification(@contact).deliver_now
      flash[:notice] = "Thank you for your message! We'll get back to you soon."
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
