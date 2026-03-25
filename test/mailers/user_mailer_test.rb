require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def setup
    @user = users(:one)
    default_url_options[:host] = 'localhost'
    default_url_options[:port] = 3000
  end

  # ─── welcome_email ─────────────────────────────────────────────────────────

  test 'welcome_email is sent to the user' do
    mail = UserMailer.welcome_email(@user)
    assert_equal [@user.email], mail.to
  end

  test 'welcome_email is sent from the Mellow Menu address' do
    mail = UserMailer.welcome_email(@user)
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'welcome_email has correct subject' do
    mail = UserMailer.welcome_email(@user)
    assert_equal 'Welcome to Mellow Menu', mail.subject
  end

  test 'welcome_email HTML body contains welcome heading' do
    mail = UserMailer.welcome_email(@user)
    assert_match(/Welcome to Mellow Menu/i, mail.html_part.body.decoded)
  end

  test 'welcome_email HTML body includes dashboard CTA button' do
    mail = UserMailer.welcome_email(@user)
    assert_match(/Go to Dashboard/i, mail.html_part.body.decoded)
  end

  test 'welcome_email HTML body contains Mellow Menu branding in layout' do
    mail = UserMailer.welcome_email(@user)
    html = mail.html_part.body.decoded
    assert_match(/mellow\.menu/i, html)
  end

  test 'welcome_email has a plain-text part' do
    mail = UserMailer.welcome_email(@user)
    assert_not_nil mail.text_part
    assert_match(/Welcome to Mellow Menu/i, mail.text_part.body.decoded)
  end

  test 'welcome_email HTML layout footer contains copyright' do
    mail = UserMailer.welcome_email(@user)
    assert_match(/Mellow Menu\. All rights reserved/i, mail.html_part.body.decoded)
  end

  test 'welcome_email HTML layout footer contains contact link' do
    mail = UserMailer.welcome_email(@user)
    assert_match(%r{mellow\.menu/#contact}i, mail.html_part.body.decoded)
  end

  test 'welcome_email is deliverable without error' do
    mail = UserMailer.welcome_email(@user)
    assert_nothing_raised { mail.deliver_now }
  end

  # ─── reset_password_instructions ───────────────────────────────────────────

  test 'reset_password_instructions is sent to the user' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_equal [@user.email], mail.to
  end

  test 'reset_password_instructions is sent from the Mellow Menu address' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_equal ['hello@mellow.menu'], mail.from
  end

  test 'reset_password_instructions has correct subject' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_match(/Reset your Mellow Menu password/i, mail.subject)
  end

  test 'reset_password_instructions HTML body contains reset link with token' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_match(/reset_tok/, mail.html_part.body.decoded)
  end

  test 'reset_password_instructions HTML body contains reset CTA button' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_match(/Reset my password/i, mail.html_part.body.decoded)
  end

  test 'reset_password_instructions HTML body contains safety notice' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_match(/didn.*t request/i, mail.html_part.body.decoded)
  end

  test 'reset_password_instructions has a plain-text part with token link' do
    mail = UserMailer.reset_password_instructions(@user, 'reset_tok')
    assert_not_nil mail.text_part
    assert_match(/reset_tok/, mail.text_part.body.decoded)
  end

  # ─── unlock_instructions ───────────────────────────────────────────────────

  test 'unlock_instructions is sent to the user' do
    mail = UserMailer.unlock_instructions(@user, 'unlock_tok')
    assert_equal [@user.email], mail.to
  end

  test 'unlock_instructions has correct subject' do
    mail = UserMailer.unlock_instructions(@user, 'unlock_tok')
    assert_match(/Unlock your Mellow Menu account/i, mail.subject)
  end

  test 'unlock_instructions HTML body contains unlock link with token' do
    mail = UserMailer.unlock_instructions(@user, 'unlock_tok')
    assert_match(/unlock_tok/, mail.html_part.body.decoded)
  end

  test 'unlock_instructions HTML body contains unlock CTA button' do
    mail = UserMailer.unlock_instructions(@user, 'unlock_tok')
    assert_match(/Unlock my account/i, mail.html_part.body.decoded)
  end

  test 'unlock_instructions has a plain-text part' do
    mail = UserMailer.unlock_instructions(@user, 'unlock_tok')
    assert_not_nil mail.text_part
    assert_match(/unlock_tok/, mail.text_part.body.decoded)
  end

  # ─── password_change ───────────────────────────────────────────────────────

  test 'password_change is sent to the user' do
    mail = UserMailer.password_change(@user)
    assert_equal [@user.email], mail.to
  end

  test 'password_change has correct subject' do
    mail = UserMailer.password_change(@user)
    assert_match(/password has been changed/i, mail.subject)
  end

  test 'password_change HTML body confirms the change' do
    mail = UserMailer.password_change(@user)
    assert_match(/successfully updated/i, mail.html_part.body.decoded)
  end

  test 'password_change has a plain-text part' do
    mail = UserMailer.password_change(@user)
    assert_not_nil mail.text_part
    assert_match(/successfully updated/i, mail.text_part.body.decoded)
  end

  # ─── email_changed ─────────────────────────────────────────────────────────

  test 'email_changed is sent to the user' do
    mail = UserMailer.email_changed(@user)
    assert_equal [@user.email], mail.to
  end

  test 'email_changed has correct subject' do
    mail = UserMailer.email_changed(@user)
    assert_match(/email address has been updated/i, mail.subject)
  end

  test 'email_changed HTML body contains email reference' do
    mail = UserMailer.email_changed(@user)
    assert_match(@user.email, mail.html_part.body.decoded)
  end

  test 'email_changed has a plain-text part' do
    mail = UserMailer.email_changed(@user)
    assert_not_nil mail.text_part
  end

  # ─── layout branding checks across all active email types ──────────────────

  test 'all email types include the layout footer with privacy policy link' do
    emails = [
      UserMailer.welcome_email(@user),
      UserMailer.reset_password_instructions(@user, 'tok'),
      UserMailer.unlock_instructions(@user, 'tok'),
      UserMailer.password_change(@user),
      UserMailer.email_changed(@user),
    ]

    emails.each do |mail|
      assert_match(
        /Privacy Policy/i,
        mail.html_part.body.decoded,
        "Expected '#{mail.subject}' to contain 'Privacy Policy' in footer",
      )
    end
  end

  test 'all email types are sent from the Mellow Menu branded address' do
    emails = [
      UserMailer.welcome_email(@user),
      UserMailer.reset_password_instructions(@user, 'tok'),
      UserMailer.unlock_instructions(@user, 'tok'),
      UserMailer.password_change(@user),
      UserMailer.email_changed(@user),
    ]

    emails.each do |mail|
      assert_equal(
        ['hello@mellow.menu'],
        mail.from,
        "Expected '#{mail.subject}' to be sent from hello@mellow.menu",
      )
    end
  end

  test 'all email types have both HTML and plain-text parts' do
    emails = [
      UserMailer.welcome_email(@user),
      UserMailer.reset_password_instructions(@user, 'tok'),
      UserMailer.unlock_instructions(@user, 'tok'),
      UserMailer.password_change(@user),
      UserMailer.email_changed(@user),
    ]

    emails.each do |mail|
      assert_not_nil(
        mail.html_part,
        "Expected '#{mail.subject}' to have an HTML part",
      )
      assert_not_nil(
        mail.text_part,
        "Expected '#{mail.subject}' to have a plain-text part",
      )
    end
  end
end
