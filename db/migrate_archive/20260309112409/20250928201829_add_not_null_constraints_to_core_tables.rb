class AddNotNullConstraintsToCoreTables < ActiveRecord::Migration[7.1]
  def up
    # OCR Tables - Add NOT NULL constraints with safe backfill
    
    # 1. ocr_menu_imports.processed_pages - backfill nulls to 0, then add constraint
    execute "UPDATE ocr_menu_imports SET processed_pages = 0 WHERE processed_pages IS NULL"
    change_column_null :ocr_menu_imports, :processed_pages, false
    
    # 2. ocr_menu_items.is_confirmed - backfill nulls to false, then add constraint  
    execute "UPDATE ocr_menu_items SET is_confirmed = false WHERE is_confirmed IS NULL"
    change_column_null :ocr_menu_items, :is_confirmed, false
    
    # 3. ocr_menu_sections.is_confirmed - backfill nulls to false, then add constraint
    execute "UPDATE ocr_menu_sections SET is_confirmed = false WHERE is_confirmed IS NULL"
    change_column_null :ocr_menu_sections, :is_confirmed, false
    
    # 4. users.admin - backfill nulls to false, then add constraint
    execute "UPDATE users SET admin = false WHERE admin IS NULL"
    change_column_null :users, :admin, false
    
    # 5. Add missing indexes for performance
    
    # Composite index for OCR item queries by section and confirmation status
    add_index :ocr_menu_items, [:ocr_menu_section_id, :is_confirmed], 
              name: 'index_ocr_menu_items_on_section_and_confirmed'
              
    # Composite index for OCR section queries by import and confirmation status  
    add_index :ocr_menu_sections, [:ocr_menu_import_id, :is_confirmed],
              name: 'index_ocr_menu_sections_on_import_and_confirmed'
              
    # Index for OCR imports by restaurant and status (common admin query)
    add_index :ocr_menu_imports, [:restaurant_id, :status],
              name: 'index_ocr_menu_imports_on_restaurant_and_status'
              
    # Index for users by plan (for billing/feature queries)
    # Note: This already exists, but adding comment for completeness
    # add_index :users, :plan_id (already exists)
  end
  
  def down
    # Remove NOT NULL constraints (safe to reverse)
    change_column_null :ocr_menu_imports, :processed_pages, true
    change_column_null :ocr_menu_items, :is_confirmed, true  
    change_column_null :ocr_menu_sections, :is_confirmed, true
    change_column_null :users, :admin, true
    
    # Remove indexes
    remove_index :ocr_menu_items, name: 'index_ocr_menu_items_on_section_and_confirmed'
    remove_index :ocr_menu_sections, name: 'index_ocr_menu_sections_on_import_and_confirmed'  
    remove_index :ocr_menu_imports, name: 'index_ocr_menu_imports_on_restaurant_and_status'
  end
end
