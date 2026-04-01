require 'test_helper'

class EmployeeMailerTest < ActionMailer::TestCase
  def setup
    @restaurant      = restaurants(:one)
    @employee        = employees(:staff_member)
    @changed_by      = employees(:one)
    @audit           = employee_role_audits(:one)
  end

  test 'role_changed delivers email to employee' do
    mail = EmployeeMailer.role_changed(@audit)

    assert_emails 1 do
      mail.deliver_now
    end
  end

  test 'role_changed uses correct recipient' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_equal [@employee.user.email], mail.to
  end

  test 'role_changed has a descriptive subject' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_includes mail.subject, @restaurant.name
    assert_includes mail.subject, 'updated'
  end

  test 'role_changed HTML body includes from_role' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_match 'Staff', mail.html_part.body.to_s
  end

  test 'role_changed HTML body includes to_role' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_match 'Manager', mail.html_part.body.to_s
  end

  test 'role_changed HTML body includes reason' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_match @audit.reason, mail.html_part.body.to_s
  end

  test 'role_changed text body includes role change summary' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_match 'Staff', mail.text_part.body.to_s
    assert_match 'Manager', mail.text_part.body.to_s
  end

  test 'role_changed sends from mellow menu address' do
    mail = EmployeeMailer.role_changed(@audit)
    assert_match 'mellow.menu', mail.from.first
  end
end
