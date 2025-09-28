require "test_helper"

class OcrMenuImportTest < ActiveSupport::TestCase
  include OcrMenuImportsTestHelper
  
  setup do
    @restaurant = restaurants(:one)
    @ocr_menu_import = OcrMenuImport.new(
      restaurant: @restaurant,
      name: "Dinner Menu",
      status: :pending
    )
  end
  
  test "should be valid with valid attributes" do
    assert @ocr_menu_import.valid?
  end
  
  test "should require a restaurant" do
    @ocr_menu_import.restaurant = nil
    assert_not @ocr_menu_import.valid?
    assert_includes @ocr_menu_import.errors[:restaurant], "must exist"
  end
  
  test "should have a default status of pending" do
    import = OcrMenuImport.new(restaurant: @restaurant, name: "Test Menu")
    assert_equal "pending", import.status
  end
  
  test "should have a valid state machine" do
    assert_respond_to @ocr_menu_import, :may_process?
    assert_respond_to @ocr_menu_import, :may_complete?
    assert_respond_to @ocr_menu_import, :may_fail?
    
    # Test state transitions
    assert @ocr_menu_import.may_process?
    @ocr_menu_import.save!
    @ocr_menu_import.process!
    assert_equal "processing", @ocr_menu_import.status
    
    assert @ocr_menu_import.may_complete?
    @ocr_menu_import.complete!
    assert_equal "completed", @ocr_menu_import.status
  end
  
  test "should attach a PDF file" do
    file = fixture_file_upload("test/fixtures/files/sample.pdf", "application/pdf")
    @ocr_menu_import.pdf_file.attach(file)
    
    assert @ocr_menu_import.pdf_file.attached?
    assert_equal "sample.pdf", @ocr_menu_import.pdf_file.filename.to_s
  end
  
  test "should have many sections and items" do
    assert_respond_to @ocr_menu_import, :ocr_menu_sections
    assert_respond_to @ocr_menu_import, :ocr_menu_items
  end
  
  test "should have scopes for different statuses" do
    assert_respond_to OcrMenuImport, :pending
    assert_respond_to OcrMenuImport, :processing
    assert_respond_to OcrMenuImport, :completed
    assert_respond_to OcrMenuImport, :failed
  end
  
  test "should update progress" do
    @ocr_menu_import.update_progress(50, 100)
    assert_equal 50, @ocr_menu_import.progress
    assert_equal 100, @ocr_menu_import.total_pages
    assert_equal 50, @ocr_menu_import.current_page
  end
  
  test "should be processable when pending" do
    @ocr_menu_import.status = :pending
    assert @ocr_menu_import.may_process?
  end
  
  test "should not be processable when already processing" do
    @ocr_menu_import.status = :processing
    assert_not @ocr_menu_import.may_process?
  end
  
  test "should be completable when processing" do
    @ocr_menu_import.status = :processing
    assert @ocr_menu_import.may_complete?
  end
  
  test "should be fail-able when processing" do
    @ocr_menu_import.status = :processing
    assert @ocr_menu_import.may_fail?
  end
  
  test "should be fail-able when pending" do
    @ocr_menu_import.status = :pending
    assert @ocr_menu_import.may_fail?
  end
  
  test "should set error message when failing" do
    error_message = "PDF processing failed"
    @ocr_menu_import.fail!(error_message)
    
    assert_equal "failed", @ocr_menu_import.status
    assert_equal error_message, @ocr_menu_import.error_message
  end
  
  test "should process menu data and create sections and items" do
    menu_data = sample_menu_data
    @ocr_menu_import.save!
    
    assert_difference -> { @ocr_menu_import.ocr_menu_sections.count }, 2 do
      assert_difference -> { OcrMenuItem.count }, 3 do
        @ocr_menu_import.process_menu_data(menu_data)
      end
    end
    
    # Reload to get associations
    @ocr_menu_import.reload
    
    # Check sections were created correctly (sort for consistent test results)
    assert_equal ["Mains", "Starters"].sort, @ocr_menu_import.ocr_menu_sections.pluck(:name).sort
    
    # Check items were created correctly
    starters = @ocr_menu_import.ocr_menu_sections.find_by(name: "Starters")
    assert_equal 2, starters.ocr_menu_items.count
    
    # Check item details
    bruschetta = starters.ocr_menu_items.find_by(name: "Bruschetta")
    assert_equal "Toasted bread with tomatoes, garlic and basil", bruschetta.description
    assert_equal 8.99, bruschetta.price.to_f
    assert_includes bruschetta.allergens, "gluten"
    assert bruschetta.is_vegetarian, "Expected Bruschetta to be vegetarian"
  end
end
