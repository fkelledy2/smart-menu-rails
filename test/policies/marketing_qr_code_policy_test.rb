# frozen_string_literal: true

require 'test_helper'

class MarketingQrCodePolicyTest < ActiveSupport::TestCase
  setup do
    @mellow_admin = users(:super_admin) # admin@mellow.menu
    @regular_user = users(:one)         # test1@gmail.com
    @qr           = marketing_qr_codes(:unlinked_qr)
  end

  # ---------------------------------------------------------------------------
  # mellow.menu admin — all actions permitted
  # ---------------------------------------------------------------------------

  test 'mellow admin can index' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).index?
  end

  test 'mellow admin can show' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).show?
  end

  test 'mellow admin can create' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).create?
  end

  test 'mellow admin can update' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).update?
  end

  test 'mellow admin can destroy' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).destroy?
  end

  test 'mellow admin can link' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).link?
  end

  test 'mellow admin can unlink' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).unlink?
  end

  test 'mellow admin can print' do
    assert MarketingQrCodePolicy.new(@mellow_admin, @qr).print?
  end

  # ---------------------------------------------------------------------------
  # Regular user — all actions denied
  # ---------------------------------------------------------------------------

  test 'regular user cannot index' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).index?
  end

  test 'regular user cannot show' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).show?
  end

  test 'regular user cannot create' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).create?
  end

  test 'regular user cannot update' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).update?
  end

  test 'regular user cannot destroy' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).destroy?
  end

  test 'regular user cannot link' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).link?
  end

  test 'regular user cannot unlink' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).unlink?
  end

  test 'regular user cannot print' do
    assert_not MarketingQrCodePolicy.new(@regular_user, @qr).print?
  end

  # ---------------------------------------------------------------------------
  # Nil user — all actions denied
  # ---------------------------------------------------------------------------

  test 'nil user cannot access any action' do
    policy = MarketingQrCodePolicy.new(nil, @qr)
    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns all records for mellow admin' do
    scope = MarketingQrCodePolicy::Scope.new(@mellow_admin, MarketingQrCode).resolve
    assert_includes scope, @qr
  end

  test 'scope returns none for regular user' do
    scope = MarketingQrCodePolicy::Scope.new(@regular_user, MarketingQrCode).resolve
    assert_empty scope
  end
end
