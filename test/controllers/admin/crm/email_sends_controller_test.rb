# frozen_string_literal: true

require 'test_helper'

class Admin::Crm::EmailSendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mellow_admin = users(:super_admin)
    @plain_admin  = users(:admin)
    @lead         = crm_leads(:contacted_lead)

    Flipper.enable(:crm_sales_funnel, @mellow_admin)
  end

  teardown do
    Flipper.disable(:crm_sales_funnel)
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  test 'unauthenticated user cannot access new email form' do
    get new_admin_crm_lead_email_send_path(@lead)
    assert_response :redirect
  end

  test 'non-mellow admin cannot access new email form' do
    sign_in @plain_admin
    get new_admin_crm_lead_email_send_path(@lead)
    assert_redirected_to root_path
  end

  test 'mellow admin can access new email form' do
    sign_in @mellow_admin
    get new_admin_crm_lead_email_send_path(@lead)
    assert_response :ok
  end

  test 'new form pre-fills to_email from lead contact_email' do
    sign_in @mellow_admin
    get new_admin_crm_lead_email_send_path(@lead)
    assert_select 'input[name="crm_email_send[to_email]"]' do |inputs|
      assert_equal @lead.contact_email, inputs.first['value']
    end
  end

  # ---------------------------------------------------------------------------
  # Create — valid params
  # ---------------------------------------------------------------------------

  test 'create with valid params enqueues SendLeadEmailJob and redirects' do
    sign_in @mellow_admin

    assert_enqueued_with(job: Crm::SendLeadEmailJob) do
      post admin_crm_lead_email_sends_path(@lead), params: {
        crm_email_send: {
          to_email: 'test@example.com',
          subject: 'Hello from mellow.menu',
          body_html: '<p>Test body</p>',
        },
      }
    end

    assert_redirected_to admin_crm_lead_path(@lead)
    assert_equal 'Email queued for delivery.', flash[:notice]
  end

  test 'create enqueues job with a job_idempotency_key' do
    sign_in @mellow_admin

    job_args = nil
    Crm::SendLeadEmailJob.stub(:perform_later, ->(crm_lead_id:, **kwargs) { job_args = kwargs }) do
      post admin_crm_lead_email_sends_path(@lead), params: {
        crm_email_send: {
          to_email: 'test@example.com',
          subject: 'Test Subject',
          body_html: '<p>Body</p>',
        },
      }
    end

    assert_not_nil job_args[:job_idempotency_key], 'job_idempotency_key should be set'
  end

  # ---------------------------------------------------------------------------
  # Create — invalid params (regression for Bug 2: no-validation-before-enqueue)
  # ---------------------------------------------------------------------------

  test 'create with blank to_email does not enqueue job and re-renders new' do
    sign_in @mellow_admin

    assert_no_enqueued_jobs only: Crm::SendLeadEmailJob do
      post admin_crm_lead_email_sends_path(@lead), params: {
        crm_email_send: {
          to_email: '',
          subject: 'Test Subject',
          body_html: '<p>Body</p>',
        },
      }
    end

    assert_response :unprocessable_content
  end

  test 'create with blank subject does not enqueue job and re-renders new' do
    sign_in @mellow_admin

    assert_no_enqueued_jobs only: Crm::SendLeadEmailJob do
      post admin_crm_lead_email_sends_path(@lead), params: {
        crm_email_send: {
          to_email: 'test@example.com',
          subject: '',
          body_html: '<p>Body</p>',
        },
      }
    end

    assert_response :unprocessable_content
  end

  # ---------------------------------------------------------------------------
  # 404 on unknown lead (regression for Bug 1: missing return after head :not_found)
  # ---------------------------------------------------------------------------

  test 'new returns 404 for unknown lead_id' do
    sign_in @mellow_admin
    get new_admin_crm_lead_email_send_path(lead_id: 0)
    assert_response :not_found
  end

  test 'create returns 404 for unknown lead_id' do
    sign_in @mellow_admin

    assert_no_enqueued_jobs only: Crm::SendLeadEmailJob do
      post admin_crm_lead_email_sends_path(lead_id: 0), params: {
        crm_email_send: { to_email: 'x@x.com', subject: 'Test', body_html: 'Hi' },
      }
    end

    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # Access control for non-mellow admin
  # ---------------------------------------------------------------------------

  test 'non-mellow admin cannot create an email send' do
    sign_in @plain_admin

    assert_no_enqueued_jobs only: Crm::SendLeadEmailJob do
      post admin_crm_lead_email_sends_path(@lead), params: {
        crm_email_send: { to_email: 'x@x.com', subject: 'Test', body_html: 'Hi' },
      }
    end

    assert_redirected_to root_path
  end
end
