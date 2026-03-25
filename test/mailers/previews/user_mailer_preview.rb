# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    user = User.first || User.new(name: 'Alex Smith', email: 'alex@example.com')
    UserMailer.welcome_email(user)
  end

  def confirmation_instructions
    user = User.first || User.new(email: 'alex@example.com')
    UserMailer.confirmation_instructions(user, 'fake_token_123')
  end

  def reset_password_instructions
    user = User.first || User.new(email: 'alex@example.com')
    UserMailer.reset_password_instructions(user, 'fake_reset_token_456')
  end

  def unlock_instructions
    user = User.first || User.new(email: 'alex@example.com')
    UserMailer.unlock_instructions(user, 'fake_unlock_token_789')
  end

  def email_changed
    user = User.first || User.new(email: 'alex@example.com')
    UserMailer.email_changed(user)
  end

  def password_change
    user = User.first || User.new(email: 'alex@example.com')
    UserMailer.password_change(user)
  end
end
