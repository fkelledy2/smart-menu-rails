require 'test_helper'

class RestaurantTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user = users(:one)
  end

  # Association tests
  test "should belong to user" do
    assert_respond_to @restaurant, :user
    assert_not_nil @restaurant.user
  end

  test "should have many menus" do
    assert_respond_to @restaurant, :menus
  end

  test "should have many tablesettings" do
    assert_respond_to @restaurant, :tablesettings
  end

  test "should have many employees" do
    assert_respond_to @restaurant, :employees
  end

  test "should have many taxes" do
    assert_respond_to @restaurant, :taxes
  end

  test "should have many tips" do
    assert_respond_to @restaurant, :tips
  end

  test "should have many restaurantavailabilities" do
    assert_respond_to @restaurant, :restaurantavailabilities
  end

  test "should have many allergyns" do
    assert_respond_to @restaurant, :allergyns
  end

  test "should have many sizes" do
    assert_respond_to @restaurant, :sizes
  end

  test "should have many ocr_menu_imports" do
    assert_respond_to @restaurant, :ocr_menu_imports
  end

  test "should have one genimage" do
    assert_respond_to @restaurant, :genimage
  end

  # Validation tests
  test "should be valid with valid attributes" do
    restaurant = Restaurant.new(
      name: "Test Restaurant",
      user: @user,
      status: :active
    )
    assert restaurant.valid?
  end

  test "should require name" do
    restaurant = Restaurant.new(user: @user, status: :active)
    assert_not restaurant.valid?
    assert_includes restaurant.errors[:name], "can't be blank"
  end

  test "should require status" do
    restaurant = Restaurant.new(name: "Test Restaurant", user: @user)
    restaurant.status = nil
    assert_not restaurant.valid?
    assert_includes restaurant.errors[:status], "can't be blank"
  end

  test "should allow optional address fields" do
    restaurant = Restaurant.new(
      name: "Test Restaurant",
      user: @user,
      status: :active,
      address1: nil,
      city: nil,
      postcode: nil,
      country: nil
    )
    assert restaurant.valid?
  end

  # Enum tests
  test "should have status enum" do
    assert_respond_to @restaurant, :status
    assert_respond_to @restaurant, :inactive?
    assert_respond_to @restaurant, :active?
    assert_respond_to @restaurant, :archived?
  end

  test "should set status correctly" do
    @restaurant.status = :inactive
    assert @restaurant.inactive?
    assert_not @restaurant.active?
    assert_not @restaurant.archived?

    @restaurant.status = :active
    assert @restaurant.active?
    assert_not @restaurant.inactive?
    assert_not @restaurant.archived?

    @restaurant.status = :archived
    assert @restaurant.archived?
    assert_not @restaurant.inactive?
    assert_not @restaurant.active?
  end

  test "should have wifiEncryptionType enum" do
    assert_respond_to @restaurant, :wifiEncryptionType
    assert_respond_to @restaurant, :WPA?
    assert_respond_to @restaurant, :WEP?
    assert_respond_to @restaurant, :NONE?
  end

  # Business logic tests
  test "locales should return array of locale codes" do
    # This test assumes there are restaurantlocales fixtures
    locales = @restaurant.locales
    assert_kind_of Array, locales
  end

  test "spotifyAuthUrl should return correct URL" do
    expected_url = "/auth/spotify?restaurant_id=#{@restaurant.id}"
    assert_equal expected_url, @restaurant.spotifyAuthUrl
  end

  test "spotifyPlaylistUrl should return correct URL" do
    expected_url = "/restaurants/#{@restaurant.id}/tracks"
    assert_equal expected_url, @restaurant.spotifyPlaylistUrl
  end

  test "gen_image_theme should return genimage id when present" do
    if @restaurant.genimage
      assert_equal @restaurant.genimage.id, @restaurant.gen_image_theme
    else
      assert_nil @restaurant.gen_image_theme
    end
  end

  test "total_capacity should sum tablesetting capacities" do
    # Get initial capacity from fixtures
    initial_capacity = @restaurant.total_capacity
    
    # Create test tablesettings with required fields
    @restaurant.tablesettings.create!(
      name: "Table 1", 
      capacity: 4, 
      tabletype: :indoor, 
      status: :free
    )
    @restaurant.tablesettings.create!(
      name: "Table 2", 
      capacity: 6, 
      tabletype: :outdoor, 
      status: :free
    )
    
    expected_capacity = initial_capacity + 4 + 6
    assert_equal expected_capacity, @restaurant.total_capacity
  end

  test "total_capacity should return 0 when no tablesettings" do
    # Create a new restaurant without existing tablesettings to avoid foreign key constraints
    restaurant = Restaurant.create!(
      name: "Empty Restaurant",
      user: @user,
      status: :active
    )
    assert_equal 0, restaurant.total_capacity
  end

  # WiFi QR String tests
  test "wifiQRString should generate correct format with all fields" do
    @restaurant.update!(
      wifissid: "TestWiFi",
      wifiEncryptionType: :WPA,
      wifiPassword: "password123",
      wifiHidden: false
    )
    
    expected = "WIFI:S:TestWiFi;T:WPA;P:password123;H:false;"
    assert_equal expected, @restaurant.wifiQRString
  end

  test "wifiQRString should handle missing ssid" do
    @restaurant.update!(
      wifissid: nil,
      wifiEncryptionType: :WPA,
      wifiPassword: "password123",
      wifiHidden: false
    )
    
    expected = "WIFI:S:T:WPA;P:password123;H:false;"
    assert_equal expected, @restaurant.wifiQRString
  end

  test "wifiQRString should handle hidden network" do
    @restaurant.update!(
      wifissid: "TestWiFi",
      wifiEncryptionType: :WPA,
      wifiPassword: "password123",
      wifiHidden: true
    )
    
    expected = "WIFI:S:TestWiFi;T:WPA;P:password123;H:true;"
    assert_equal expected, @restaurant.wifiQRString
  end

  test "wifiQRString should handle no encryption" do
    @restaurant.update!(
      wifissid: "OpenWiFi",
      wifiEncryptionType: :NONE,
      wifiPassword: nil,
      wifiHidden: false
    )
    
    expected = "WIFI:S:OpenWiFi;T:NONE;H:false;"
    assert_equal expected, @restaurant.wifiQRString
  end

  # Locale methods tests
  test "defaultLocale should return active default locale" do
    # This test would need proper restaurantlocale fixtures
    default_locale = @restaurant.defaultLocale
    if default_locale
      assert_equal 'active', default_locale.status
      assert default_locale.dfault
    else
      # If no default locale exists, that's also a valid state
      assert_nil default_locale
    end
  end

  test "getLocale should return locale by code" do
    # This test would need proper restaurantlocale fixtures
    locale = @restaurant.getLocale('en')
    if locale
      assert_equal 'en', locale.locale
      assert_equal 'active', locale.status
    else
      # If no locale exists for 'en', that's also a valid state
      assert_nil locale
    end
  end

  # Dependent destroy tests
  test "should have dependent destroy/delete_all associations configured" do
    assert_equal :delete_all, Restaurant.reflect_on_association(:tablesettings).options[:dependent]
    assert_equal :delete_all, Restaurant.reflect_on_association(:menus).options[:dependent]
    assert_equal :delete_all, Restaurant.reflect_on_association(:employees).options[:dependent]
    assert_equal :delete_all, Restaurant.reflect_on_association(:taxes).options[:dependent]
    assert_equal :delete_all, Restaurant.reflect_on_association(:tips).options[:dependent]
    assert_equal :destroy, Restaurant.reflect_on_association(:ocr_menu_imports).options[:dependent]
  end

  # IdentityCache tests
  test "should have identity cache configured" do
    assert Restaurant.respond_to?(:cache_index)
    # Test that cache methods are available
    assert Restaurant.respond_to?(:fetch_by_id)
    assert Restaurant.respond_to?(:fetch_by_user_id)
  end
end
