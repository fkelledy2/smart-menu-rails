class ContactMailer < ApplicationMailer
  default from: 'admin@mellow.menu'

  def notification(contact)
    @contact = contact
    mail(to: "admin@mellow.menu", subject: "New Contact Form Submission")
  end

  def receipt(contact)
    @contact = contact
    mail(to: @contact.email, subject: "Mellow Menu: Thanks for connecting!")
  end
end
