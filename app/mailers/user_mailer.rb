class UserMailer < Devise::Mailer
  layout 'mailer'
  helper :application
  include Devise::Controllers::UrlHelpers

  default template_path: 'user_mailer'
  default from: 'Mellow Menu <admin@mellow.menu>'

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Welcome to Mellow Menu')
  end

  def reset_password_instructions(record, token, opts = {})
    @resource = record
    @token = token
    mail(to: record.email, subject: 'Reset your Mellow Menu password')
  end

  def unlock_instructions(record, token, opts = {})
    opts[:subject] = 'Unlock your Mellow Menu account'
    super
  end

  def email_changed(record, opts = {})
    opts[:subject] = 'Your Mellow Menu email address has been updated'
    super
  end

  def password_change(record, opts = {})
    opts[:subject] = 'Your Mellow Menu password has been changed'
    super
  end
end
