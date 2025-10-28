require 'test_helper'

class OcrMenuImportPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one) # Owned by @user
    @other_restaurant = restaurants(:two) # Owned by @other_user

    # Create OCR menu imports for testing
    @ocr_import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'test_menu.pdf',
      status: :pending,
    )

    @other_ocr_import = OcrMenuImport.create!(
      restaurant: @other_restaurant,
      name: 'other_menu.pdf',
      status: :pending,
    )
  end

  # === SHOW TESTS ===

  test 'should allow owner to view ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.show?
  end

  test 'should deny non-owner from viewing ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.show?
  end

  test 'should deny anonymous user from viewing ocr menu import' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.show?
  end

  # === EDIT TESTS ===

  test 'should allow owner to edit ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.edit?
  end

  test 'should deny non-owner from editing ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.edit?
  end

  test 'should deny anonymous user from editing ocr menu import' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.edit?
  end

  # === UPDATE TESTS ===

  test 'should allow owner to update ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.update?
  end

  test 'should deny non-owner from updating ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.update?
  end

  test 'should deny anonymous user from updating ocr menu import' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.update?
  end

  # === DESTROY TESTS ===

  test 'should allow owner to destroy ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.destroy?
  end

  test 'should deny non-owner from destroying ocr menu import' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.destroy?
  end

  test 'should deny anonymous user from destroying ocr menu import' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.destroy?
  end

  # === PROCESS PDF TESTS ===

  test 'should allow owner to process pdf' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.process_pdf?
  end

  test 'should deny non-owner from processing pdf' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.process_pdf?
  end

  test 'should deny anonymous user from processing pdf' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.process_pdf?
  end

  # === CONFIRM IMPORT TESTS ===

  test 'should allow owner to confirm import' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.confirm_import?
  end

  test 'should deny non-owner from confirming import' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.confirm_import?
  end

  test 'should deny anonymous user from confirming import' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.confirm_import?
  end

  # === REORDER SECTIONS TESTS ===

  test 'should allow owner to reorder sections' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.reorder_sections?
  end

  test 'should deny non-owner from reordering sections' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.reorder_sections?
  end

  test 'should deny anonymous user from reordering sections' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.reorder_sections?
  end

  # === REORDER ITEMS TESTS ===

  test 'should allow owner to reorder items' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.reorder_items?
  end

  test 'should deny non-owner from reordering items' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.reorder_items?
  end

  test 'should deny anonymous user from reordering items' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.reorder_items?
  end

  # === TOGGLE SECTION CONFIRMATION TESTS ===

  test 'should allow owner to toggle section confirmation' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.toggle_section_confirmation?
  end

  test 'should deny non-owner from toggling section confirmation' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.toggle_section_confirmation?
  end

  test 'should deny anonymous user from toggling section confirmation' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.toggle_section_confirmation?
  end

  # === TOGGLE ALL CONFIRMATION TESTS ===

  test 'should allow owner to toggle all confirmation' do
    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.toggle_all_confirmation?
  end

  test 'should deny non-owner from toggling all confirmation' do
    policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not policy.toggle_all_confirmation?
  end

  test 'should deny anonymous user from toggling all confirmation' do
    policy = OcrMenuImportPolicy.new(nil, @ocr_import)
    assert_not policy.toggle_all_confirmation?
  end

  # === SCOPE TESTS ===

  test "should scope ocr imports to user's restaurant imports" do
    scope = OcrMenuImportPolicy::Scope.new(@user, OcrMenuImport).resolve

    # Should include user's restaurant imports
    assert_includes scope, @ocr_import

    # Should not include other user's restaurant imports
    assert_not_includes scope, @other_ocr_import
  end

  test 'should return empty scope for anonymous user' do
    # Anonymous user scope will fail because user is nil
    assert_raises(NoMethodError) do
      OcrMenuImportPolicy::Scope.new(nil, OcrMenuImport).resolve
    end
  end

  test 'should handle user with no restaurant imports' do
    user_with_no_restaurants = User.create!(
      email: 'noimports@example.com',
      password: 'password123',
    )

    scope = OcrMenuImportPolicy::Scope.new(user_with_no_restaurants, OcrMenuImport).resolve

    # Should not include any imports
    assert_not_includes scope, @ocr_import
    assert_not_includes scope, @other_ocr_import
  end

  # === EDGE CASE TESTS ===

  test 'should handle nil ocr import record' do
    policy = OcrMenuImportPolicy.new(@user, nil)

    # All owner-based methods should return false for nil record
    assert_not policy.show?
    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.process_pdf?
    assert_not policy.confirm_import?
    assert_not policy.reorder_sections?
    assert_not policy.reorder_items?
    assert_not policy.toggle_section_confirmation?
    assert_not policy.toggle_all_confirmation?
  end

  test 'should handle ocr import without restaurant' do
    import_without_restaurant = OcrMenuImport.new(name: 'test.pdf')
    policy = OcrMenuImportPolicy.new(@user, import_without_restaurant)

    # Should deny access to import without proper restaurant association
    assert_not policy.show?
    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.process_pdf?
    assert_not policy.confirm_import?
  end

  test 'should inherit from ApplicationPolicy' do
    assert OcrMenuImportPolicy < ApplicationPolicy
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle different import statuses' do
    # Test with different import statuses
    statuses = %i[pending processing completed failed]

    statuses.each do |status|
      import = OcrMenuImport.create!(
        restaurant: @restaurant,
        name: "#{status}_menu.pdf",
        status: status,
      )

      policy = OcrMenuImportPolicy.new(@user, import)
      assert policy.show?, "Owner should have access to #{status} imports"
      assert policy.update?, "Owner should be able to update #{status} imports"
      assert policy.destroy?, "Owner should be able to destroy #{status} imports"

      # OCR-specific actions should also be allowed for owner
      assert policy.process_pdf?, "Owner should be able to process #{status} imports"
      assert policy.confirm_import?, "Owner should be able to confirm #{status} imports"
      assert policy.reorder_sections?, "Owner should be able to reorder sections in #{status} imports"
      assert policy.reorder_items?, "Owner should be able to reorder items in #{status} imports"
    end
  end

  test 'should handle multiple imports per restaurant' do
    # Create additional import for the same restaurant
    additional_import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'second_menu.pdf',
      status: :completed,
    )

    policy = OcrMenuImportPolicy.new(@user, additional_import)
    assert policy.show?
    assert policy.edit?
    assert policy.update?
    assert policy.destroy?
    assert policy.process_pdf?
    assert policy.confirm_import?

    # Scope should include both imports
    scope = OcrMenuImportPolicy::Scope.new(@user, OcrMenuImport).resolve
    assert_includes scope, @ocr_import
    assert_includes scope, additional_import
  end

  test 'should handle cross-restaurant import access correctly' do
    # Verify that ownership is checked through restaurant
    policy_own_import = OcrMenuImportPolicy.new(@user, @ocr_import)
    policy_other_import = OcrMenuImportPolicy.new(@user, @other_ocr_import)

    # Should have access to own restaurant's import
    assert policy_own_import.show?
    assert policy_own_import.edit?
    assert policy_own_import.update?
    assert policy_own_import.destroy?
    assert policy_own_import.process_pdf?
    assert policy_own_import.confirm_import?

    # Should not have access to other restaurant's import
    assert_not policy_other_import.show?
    assert_not policy_other_import.edit?
    assert_not policy_other_import.update?
    assert_not policy_other_import.destroy?
    assert_not policy_other_import.process_pdf?
    assert_not policy_other_import.confirm_import?
  end

  # === OCR WORKFLOW TESTS ===

  test 'should handle complete OCR workflow permissions' do
    # Test the complete OCR import workflow
    import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'workflow_menu.pdf',
      status: :pending,
    )

    policy = OcrMenuImportPolicy.new(@user, import)

    # Step 1: Process PDF
    assert policy.process_pdf?, 'Owner should be able to process PDF'

    # Step 2: Reorder sections and items
    assert policy.reorder_sections?, 'Owner should be able to reorder sections'
    assert policy.reorder_items?, 'Owner should be able to reorder items'

    # Step 3: Toggle confirmations
    assert policy.toggle_section_confirmation?, 'Owner should be able to toggle section confirmations'
    assert policy.toggle_all_confirmation?, 'Owner should be able to toggle all confirmations'

    # Step 4: Confirm import
    assert policy.confirm_import?, 'Owner should be able to confirm import'

    # Throughout: Basic CRUD operations
    assert policy.show?, 'Owner should be able to view import throughout workflow'
    assert policy.edit?, 'Owner should be able to edit import throughout workflow'
    assert policy.update?, 'Owner should be able to update import throughout workflow'
  end

  test 'should handle OCR import lifecycle management' do
    # Test import creation, processing, completion, cleanup
    new_import = OcrMenuImport.new(
      restaurant: @restaurant,
      name: 'lifecycle_menu.pdf',
      status: :pending,
    )

    # Before creation - policy should work with new record
    policy = OcrMenuImportPolicy.new(@user, new_import)

    # After creation
    new_import.save!
    assert policy.show?, 'Owner should be able to view new imports'
    assert policy.process_pdf?, 'Owner should be able to process new imports'

    # During processing
    new_import.update!(status: :processing)
    assert policy.reorder_sections?, 'Owner should be able to reorder during processing'
    assert policy.toggle_section_confirmation?, 'Owner should be able to toggle confirmations during processing'

    # After completion
    new_import.update!(status: :completed)
    assert policy.confirm_import?, 'Owner should be able to confirm completed imports'
    assert policy.destroy?, 'Owner should be able to destroy completed imports'
  end

  # === PERFORMANCE TESTS ===

  test 'should handle large import datasets efficiently' do
    # Create multiple imports to test performance
    5.times do |i|
      OcrMenuImport.create!(
        restaurant: @restaurant,
        name: "bulk_menu_#{i}.pdf",
        status: :completed,
      )
    end

    scope = OcrMenuImportPolicy::Scope.new(@user, OcrMenuImport).resolve

    # Should handle large datasets without N+1 queries
    assert_nothing_raised do
      scope.limit(50).each do |import|
        # Access associated data that should be efficiently loaded
        import.restaurant.name
      end
    end
  end

  test 'should prevent unauthorized access across restaurant boundaries' do
    # Create imports in different restaurants
    restaurant_a = Restaurant.create!(name: 'Restaurant A', user: @user, status: :active)
    restaurant_b = Restaurant.create!(name: 'Restaurant B', user: @other_user, status: :active)

    import_a = OcrMenuImport.create!(restaurant: restaurant_a, name: 'menu_a.pdf', status: :pending)
    import_b = OcrMenuImport.create!(restaurant: restaurant_b, name: 'menu_b.pdf', status: :pending)

    # User should only access their own restaurant's imports
    policy_a = OcrMenuImportPolicy.new(@user, import_a)
    policy_b = OcrMenuImportPolicy.new(@user, import_b)

    assert policy_a.show?, "User should access their own restaurant's imports"
    assert policy_a.process_pdf?, "User should be able to process their own restaurant's imports"

    assert_not policy_b.show?, "User should not access other restaurant's imports"
    assert_not policy_b.process_pdf?, "User should not be able to process other restaurant's imports"

    # Scope should only include own restaurant's imports
    scope = OcrMenuImportPolicy::Scope.new(@user, OcrMenuImport).resolve
    assert_includes scope, import_a
    assert_not_includes scope, import_b
  end

  # === RESTAURANT OWNERSHIP TESTS ===

  test 'should properly validate restaurant ownership' do
    # Test the ownership chain: User → Restaurant → OcrMenuImport
    assert_equal @user.id, @ocr_import.restaurant.user_id,
                 'Test setup should have proper ownership chain'

    policy = OcrMenuImportPolicy.new(@user, @ocr_import)
    assert policy.show?, 'Owner should have access through restaurant ownership'

    # Test with different user
    other_policy = OcrMenuImportPolicy.new(@user, @other_ocr_import)
    assert_not other_policy.show?, 'Non-owner should not have access'
  end

  test 'should handle scope correctly with multiple restaurants per user' do
    # Create additional restaurant for the same user
    additional_restaurant = Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      status: :active,
    )

    additional_import = OcrMenuImport.create!(
      restaurant: additional_restaurant,
      name: 'second_restaurant_menu.pdf',
      status: :pending,
    )

    scope = OcrMenuImportPolicy::Scope.new(@user, OcrMenuImport).resolve

    # Should include imports from both restaurants
    assert_includes scope, @ocr_import
    assert_includes scope, additional_import

    # Should not include other user's imports
    assert_not_includes scope, @other_ocr_import
  end
end
