# frozen_string_literal: true

require 'test_helper'

module MarketingQrCodes
  class ResolveServiceTest < ActiveSupport::TestCase
    # -------------------------------------------------------------------------
    # Not found
    # -------------------------------------------------------------------------

    test 'returns not_found for unknown token' do
      result = ResolveService.call(token: 'no-such-token')
      assert_equal :not_found, result.outcome
    end

    test 'returns not_found for archived QR' do
      qr = marketing_qr_codes(:archived_qr)
      result = ResolveService.call(token: qr.token)
      assert_equal :not_found, result.outcome
    end

    test 'returns not_found when linked QR has no smartmenu' do
      qr = marketing_qr_codes(:linked_qr).dup
      qr.token = SecureRandom.uuid
      qr.smartmenu = nil
      qr.save!(validate: false)

      result = ResolveService.call(token: qr.token)
      assert_equal :not_found, result.outcome
    end

    # -------------------------------------------------------------------------
    # Holding
    # -------------------------------------------------------------------------

    test 'returns holding for unlinked QR with no custom holding_url' do
      qr = marketing_qr_codes(:unlinked_qr)
      result = ResolveService.call(token: qr.token)

      assert_equal :holding, result.outcome
      assert_equal 'https://mellow.menu', result.holding_url
    end

    test 'returns holding with custom holding_url' do
      qr = marketing_qr_codes(:holding_url_qr)
      result = ResolveService.call(token: qr.token)

      assert_equal :holding, result.outcome
      assert_equal 'https://example.com/coming-soon', result.holding_url
    end

    # -------------------------------------------------------------------------
    # Redirect to smartmenu
    # -------------------------------------------------------------------------

    test 'returns redirect_to_smartmenu for linked QR' do
      qr = marketing_qr_codes(:linked_qr)
      result = ResolveService.call(token: qr.token)

      assert_equal :redirect_to_smartmenu, result.outcome
      assert_equal qr.smartmenu.public_token, result.smartmenu_public_token
    end

    test 'result qr is the matching record' do
      qr = marketing_qr_codes(:unlinked_qr)
      result = ResolveService.call(token: qr.token)

      assert_equal qr.id, result.qr.id
    end
  end
end
