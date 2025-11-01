require 'test_helper'

class MenuEditSessionTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @user = users(:one)
    @session = MenuEditSession.create!(
      menu: @menu,
      user: @user,
      session_id: 'test-session-123'
    )
  end

  # Association tests
  test 'belongs to menu' do
    assert_respond_to @session, :menu
    assert_not_nil @session.menu
    assert_equal @menu, @session.menu
  end

  test 'belongs to user' do
    assert_respond_to @session, :user
    assert_not_nil @session.user
    assert_equal @user, @session.user
  end

  test 'requires menu' do
    session = MenuEditSession.new(user: @user)
    assert_not session.valid?
    assert_includes session.errors[:menu], "must exist"
  end

  test 'requires user' do
    session = MenuEditSession.new(menu: @menu)
    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"
  end

  test 'can create session with valid attributes' do
    menu2 = menus(:two)
    session = MenuEditSession.new(
      menu: menu2,
      user: @user,
      session_id: 'new-session-456'
    )
    assert session.valid?
    assert session.save
  end

  test 'multiple users can have sessions for same menu' do
    user2 = users(:two)
    session2 = MenuEditSession.create!(
      menu: @menu,
      user: user2,
      session_id: 'session-user2'
    )
    
    assert_not_nil session2
    assert_equal @menu, session2.menu
    assert_equal user2, session2.user
  end

  test 'same user can have sessions for multiple menus' do
    menu2 = menus(:two)
    session2 = MenuEditSession.create!(
      menu: menu2,
      user: @user,
      session_id: 'session-menu2'
    )
    
    assert_not_nil session2
    assert_equal menu2, session2.menu
    assert_equal @user, session2.user
  end

  test 'can destroy session' do
    assert_difference 'MenuEditSession.count', -1 do
      @session.destroy
    end
  end
end
