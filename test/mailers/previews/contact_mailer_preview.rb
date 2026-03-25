# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def receipt
    contact = Contact.new(
      email: 'chef@example.com',
      message: 'I would love to learn more about Mellow Menu for my restaurant.',
    )
    ContactMailer.receipt(contact)
  end

  def notification
    contact = Contact.new(
      email: 'chef@example.com',
      message: 'I would love to learn more about Mellow Menu for my restaurant.',
    )
    ContactMailer.notification(contact)
  end
end
