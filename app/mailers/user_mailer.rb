class UserMailer < Devise::Mailer
  layout 'mailer'
  helper :application # Allows using view helpers in email templates
  include Devise::Controllers::UrlHelpers # Enables Devise URL helpers
  default template_path: 'user_mailer' # Points to custom view folder

  default from: 'admin@mellow.menu'

  def welcome_email(user)
      @user = user
      mail(to:@user.email, subject: 'Welcome to Mellow Menu')
  end

  # Override confirmation instructions
  def confirmation_instructions(record, token, opts = {})
    opts[:subject] = "Confirm Your Account"
    super
  end

  # Override reset password email
  def reset_password_instructions(record, token, opts = {})
    opts[:subject] = "Reset Your Password"
    @resource = record
    @token = token
    puts record.email
    mail(to:record.email, subject: opts[:subject])
  end

  # Override unlock instructions (if using :lockable)
  def unlock_instructions(record, token, opts = {})
    opts[:subject] = "Unlock Your Account"
    super
  end
end
