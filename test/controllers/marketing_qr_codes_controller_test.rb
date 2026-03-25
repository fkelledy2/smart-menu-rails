# frozen_string_literal: true

require 'test_helper'

class MarketingQrCodesControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # Resolve — unlinked
  # ---------------------------------------------------------------------------

  test 'GET /m/:token renders holding page for unlinked QR' do
    qr = marketing_qr_codes(:unlinked_qr)
    get marketing_qr_code_resolve_path(token: qr.token)
    assert_response :ok
    assert_select 'h1', /Menu launching soon/i
  end

  test 'GET /m/:token redirects to custom holding_url when set' do
    qr = marketing_qr_codes(:holding_url_qr)
    get marketing_qr_code_resolve_path(token: qr.token)
    assert_redirected_to 'https://example.com/coming-soon'
  end

  # ---------------------------------------------------------------------------
  # Resolve — linked
  # ---------------------------------------------------------------------------

  test 'GET /m/:token redirects to /t/:public_token for linked QR' do
    qr = marketing_qr_codes(:linked_qr)
    get marketing_qr_code_resolve_path(token: qr.token)
    assert_redirected_to table_link_path(qr.smartmenu.public_token)
  end

  # ---------------------------------------------------------------------------
  # Resolve — not found / archived
  # ---------------------------------------------------------------------------

  test 'GET /m/:invalid_token returns 404' do
    get marketing_qr_code_resolve_path(token: 'no-such-token')
    assert_response :not_found
  end

  test 'GET /m/:archived_token returns 404' do
    qr = marketing_qr_codes(:archived_qr)
    get marketing_qr_code_resolve_path(token: qr.token)
    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # No auth required
  # ---------------------------------------------------------------------------

  test 'resolve does not require authentication' do
    qr = marketing_qr_codes(:unlinked_qr)
    # Not signed in — should still respond
    get marketing_qr_code_resolve_path(token: qr.token)
    assert_response :ok
  end
end
