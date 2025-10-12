require 'test_helper'

class OrdractionTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user = users(:one)
    @menu = menus(:one)
    @tablesetting = tablesettings(:one)
    
    @ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting
    )
    
    @ordrparticipant = Ordrparticipant.create!(
      ordr: @ordr,
      sessionid: "test_session_123",
      preferredlocale: "en"
    )
    
    @menuitem = menuitems(:one)
    @ordritem = Ordritem.create!(
      ordr: @ordr,
      menuitem: @menuitem
    )
    
    @ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      action: :participate
    )
  end

  # === VALIDATION TESTS ===
  
  test "should be valid with valid attributes" do
    assert @ordraction.valid?
  end

  test "should require action" do
    @ordraction.action = nil
    assert_not @ordraction.valid?
    assert_includes @ordraction.errors[:action], "can't be blank"
  end

  # === ASSOCIATION TESTS ===
  
  test "should belong to ordrparticipant" do
    assert_respond_to @ordraction, :ordrparticipant
    assert_instance_of Ordrparticipant, @ordraction.ordrparticipant
  end

  test "should belong to ordr" do
    assert_respond_to @ordraction, :ordr
    assert_instance_of Ordr, @ordraction.ordr
  end

  test "should belong to ordritem optionally" do
    assert_respond_to @ordraction, :ordritem
    # Should be valid without ordritem
    @ordraction.ordritem = nil
    assert @ordraction.valid?
  end

  test "should require ordrparticipant" do
    @ordraction.ordrparticipant = nil
    assert_not @ordraction.valid?
    assert_includes @ordraction.errors[:ordrparticipant], "must exist"
  end

  test "should require ordr" do
    @ordraction.ordr = nil
    assert_not @ordraction.valid?
    assert_includes @ordraction.errors[:ordr], "must exist"
  end

  # === ENUM TESTS ===
  
  test "should have correct action enum values" do
    assert_equal 0, Ordraction.actions[:participate]
    assert_equal 1, Ordraction.actions[:openorder]
    assert_equal 2, Ordraction.actions[:additem]
    assert_equal 3, Ordraction.actions[:removeitem]
    assert_equal 4, Ordraction.actions[:requestbill]
    assert_equal 5, Ordraction.actions[:closeorder]
  end

  test "should allow action changes" do
    @ordraction.participate!
    assert @ordraction.participate?
    
    @ordraction.openorder!
    assert @ordraction.openorder?
    
    @ordraction.additem!
    assert @ordraction.additem?
    
    @ordraction.removeitem!
    assert @ordraction.removeitem?
    
    @ordraction.requestbill!
    assert @ordraction.requestbill?
    
    @ordraction.closeorder!
    assert @ordraction.closeorder?
  end

  # === FACTORY/CREATION TESTS ===
  
  test "should create participate action" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      action: :participate
    )
    assert ordraction.save
    assert ordraction.participate?
  end

  test "should create openorder action" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      action: :openorder
    )
    assert ordraction.save
    assert ordraction.openorder?
  end

  test "should create additem action with ordritem" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      ordritem: @ordritem,
      action: :additem
    )
    assert ordraction.save
    assert ordraction.additem?
    assert_equal @ordritem, ordraction.ordritem
  end

  test "should create removeitem action with ordritem" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      ordritem: @ordritem,
      action: :removeitem
    )
    assert ordraction.save
    assert ordraction.removeitem?
    assert_equal @ordritem, ordraction.ordritem
  end

  test "should create requestbill action" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      action: :requestbill
    )
    assert ordraction.save
    assert ordraction.requestbill?
  end

  test "should create closeorder action" do
    ordraction = Ordraction.new(
      ordrparticipant: @ordrparticipant,
      ordr: @ordr,
      action: :closeorder
    )
    assert ordraction.save
    assert ordraction.closeorder?
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should create action without ordritem for non-item actions" do
    [:participate, :openorder, :requestbill, :closeorder].each do |action_type|
      ordraction = Ordraction.new(
        ordrparticipant: @ordrparticipant,
        ordr: @ordr,
        action: action_type
      )
      assert ordraction.valid?, "#{action_type} action should be valid without ordritem"
      assert ordraction.save
    end
  end

  test "should allow ordritem for item-related actions" do
    [:additem, :removeitem].each do |action_type|
      ordraction = Ordraction.new(
        ordrparticipant: @ordrparticipant,
        ordr: @ordr,
        ordritem: @ordritem,
        action: action_type
      )
      assert ordraction.valid?, "#{action_type} action should be valid with ordritem"
      assert ordraction.save
    end
  end

  # === IDENTITY CACHE TESTS ===
  
  test "should have identity cache configured" do
    assert Ordraction.respond_to?(:cache_index)
    assert Ordraction.respond_to?(:fetch_by_id)
    assert Ordraction.respond_to?(:fetch_by_ordrparticipant_id)
    assert Ordraction.respond_to?(:fetch_by_ordr_id)
    assert Ordraction.respond_to?(:fetch_by_ordritem_id)
  end

  # === EDGE CASE TESTS ===
  
  test "should handle invalid action enum" do
    assert_raises(ArgumentError) do
      @ordraction.action = "invalid_action"
    end
  end

  test "should handle nil associations gracefully" do
    ordraction = Ordraction.new(action: :participate)
    assert_not ordraction.valid?
    assert_includes ordraction.errors[:ordrparticipant], "must exist"
    assert_includes ordraction.errors[:ordr], "must exist"
  end
end
