# frozen_string_literal: true

require 'test_helper'

class MarketingQrCodeTest < ActiveSupport::TestCase
  setup do
    @admin = users(:super_admin)
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'valid with required attributes' do
    qr = MarketingQrCode.new(created_by_user_id: @admin.id)
    assert qr.valid?, qr.errors.full_messages.inspect
  end

  test 'invalid without created_by_user' do
    qr = MarketingQrCode.new
    qr.valid?
    # belongs_to (non-optional) validates presence on the association, not the _id column
    assert qr.errors[:created_by_user].any?, 'Expected errors on created_by_user'
  end

  test 'invalid with duplicate token' do
    existing = marketing_qr_codes(:unlinked_qr)
    qr = MarketingQrCode.new(created_by_user_id: @admin.id, token: existing.token)
    qr.valid?
    assert_includes qr.errors[:token], 'has already been taken'
  end

  # ---------------------------------------------------------------------------
  # Token generation
  # ---------------------------------------------------------------------------

  test 'auto-generates UUID token on create' do
    qr = MarketingQrCode.create!(created_by_user_id: @admin.id)
    assert qr.token.present?
    assert_match(/\A[0-9a-f-]{36}\z/i, qr.token)
  end

  test 'does not overwrite existing token on create' do
    qr = MarketingQrCode.create!(created_by_user_id: @admin.id, token: 'my-custom-token')
    assert_equal 'my-custom-token', qr.token
  end

  test 'token is readonly after creation — raises on update' do
    qr = MarketingQrCode.create!(created_by_user_id: @admin.id)
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      qr.update!(token: 'changed-token')
    end
  end

  # ---------------------------------------------------------------------------
  # Status enum
  # ---------------------------------------------------------------------------

  test 'defaults to unlinked status' do
    qr = MarketingQrCode.create!(created_by_user_id: @admin.id)
    assert qr.unlinked?
  end

  test 'transitions to linked' do
    qr = marketing_qr_codes(:unlinked_qr)
    qr.update!(status: :linked)
    assert qr.linked?
  end

  test 'transitions to archived' do
    qr = marketing_qr_codes(:unlinked_qr)
    qr.update!(status: :archived)
    assert qr.archived?
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test 'active scope excludes archived' do
    active = MarketingQrCode.active
    assert_not_includes active, marketing_qr_codes(:archived_qr)
    assert_includes active, marketing_qr_codes(:unlinked_qr)
    assert_includes active, marketing_qr_codes(:linked_qr)
  end

  # ---------------------------------------------------------------------------
  # Instance methods
  # ---------------------------------------------------------------------------

  test 'public_url returns correct URL' do
    qr = marketing_qr_codes(:unlinked_qr)
    url = qr.public_url
    assert_equal "https://mellow.menu/m/#{qr.token}", url
  end

  test 'public_url accepts host and protocol overrides' do
    qr = marketing_qr_codes(:unlinked_qr)
    url = qr.public_url(host: 'localhost:3000', protocol: 'http')
    assert_equal "http://localhost:3000/m/#{qr.token}", url
  end

  test 'effective_holding_url returns holding_url when set' do
    qr = marketing_qr_codes(:holding_url_qr)
    assert_equal 'https://example.com/coming-soon', qr.effective_holding_url
  end

  test 'effective_holding_url returns mellow.menu default when holding_url is blank' do
    qr = marketing_qr_codes(:unlinked_qr)
    assert_equal 'https://mellow.menu', qr.effective_holding_url
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test 'belongs to created_by_user' do
    qr = marketing_qr_codes(:unlinked_qr)
    assert_equal @admin, qr.created_by_user
  end

  test 'linked_qr belongs to restaurant, menu, tablesetting, and smartmenu' do
    qr = marketing_qr_codes(:linked_qr)
    assert_not_nil qr.restaurant
    assert_not_nil qr.menu
    assert_not_nil qr.tablesetting
    assert_not_nil qr.smartmenu
  end
end
