# frozen_string_literal: true

# OCR Menu Imports
resources :ocr_menu_imports, only: [] do
  member do
    post :process_pdf
    post :confirm_import
  end
  collection do
    get :new_import
  end
end
