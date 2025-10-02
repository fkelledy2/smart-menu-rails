require 'sidekiq/web'

Rails.application.routes.draw do
  # ============================================================================
  # ROOT AND AUTHENTICATION
  # ============================================================================
  root to: "home#index", defaults: { format: :html }
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  
  # ============================================================================
  # PUBLIC PAGES
  # ============================================================================
  get '/privacy', to: 'home#privacy'
  get '/terms', to: 'home#terms'
  
  # ============================================================================
  # HEALTH AND MONITORING
  # ============================================================================
  get "up" => "rails/health#show", as: :rails_health_check
  get '/.well-known/appspecific/com.chrome.devtools.json', to: proc { [204, {}, ['']] }
  
  # ============================================================================
  # API ENDPOINTS
  # ============================================================================
  namespace :api do
    namespace :v1 do
      # Test endpoints
      get 'test/ping', to: 'test#ping'
      
      # Google Vision API endpoints
      post 'vision/analyze', to: 'vision#analyze'
      post 'vision/detect_menu_items', to: 'vision#detect_menu_items'
      
      # OCR management
      resources :ocr_menu_items, only: [:update]
      resources :ocr_menu_sections, only: [:update]
      
      # Analytics tracking endpoints
      post 'analytics/track', to: 'analytics#track'
      post 'analytics/track_anonymous', to: 'analytics#track_anonymous'
    end
  end
  
  # ============================================================================
  # ONBOARDING AND USER MANAGEMENT
  # ============================================================================
  get 'onboarding', to: 'onboarding#show'
  get 'onboarding/step/:step', to: 'onboarding#show', as: :onboarding_step
  patch 'onboarding', to: 'onboarding#update'
  post 'onboarding', to: 'onboarding#update'
  
  resources :contacts, only: [:new, :create]
  resources :notifications, only: [:index]
  resources :announcements, only: [:index]
  
  # ============================================================================
  # SUBSCRIPTION AND BILLING
  # ============================================================================
  resources :plans
  resources :features
  resources :features_plans
  resources :userplans
  resources :testimonials
  
  # Payment endpoints
  post "/create_payment_link", to: "payments#create_payment_link"
  post "/generate_qr", to: "payments#generate_qr"
  
  # ============================================================================
  # RESTAURANT MANAGEMENT (Main Business Logic)
  # ============================================================================
  resources :restaurants do
    # Restaurant configuration
    resources :restaurantlocales
    resources :tablesettings
    resources :restaurantavailabilities
    
    # Restaurant catalog management
    resources :taxes
    resources :sizes
    resources :tips
    resources :tags
    resources :allergyns
    resources :genimages
    
    # Staff management
    resources :employees
    
    # Inventory management
    resources :inventories
    
    # Order management
    resources :ordrs
    resources :ordritems
    resources :ordritemnotes
    resources :ordrparticipants
    resources :ordractions
    
    # Music/Entertainment
    resources :tracks
    
    # Menu management (limited to restaurant context)
    resources :menus, only: [:index, :show, :edit]
    
    # OCR menu import functionality
    resources :ocr_menu_imports, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        post :process_pdf
        post :confirm_import
        patch :reorder_sections
        patch :reorder_items
        patch :toggle_section_confirmation
        patch :toggle_all_confirmation
      end
    end
  end
  
  # ============================================================================
  # MENU MANAGEMENT (Full Menu Operations)
  # ============================================================================
  resources :menus do
    # Menu configuration
    resources :menuparticipants
    resources :menuavailabilities
    resources :menusectionlocales
    
    # Menu structure and content
    resources :menusections do
      resources :menuitems  # Full CRUD for menusection-specific menuitems
    end
    
    # Menu-level menuitem operations
    resources :menuitems, only: [:index]  # Bulk operations across all menusections
    resources :menuitem_size_mappings, controller: 'menuitemsizemappings', only: [:update]
    
    # Menu actions
    member do
      post :regenerate_images
      get :tablesettings, to: 'menus#show'
    end
  end
  
  # ============================================================================
  # GLOBAL RESOURCES
  # ============================================================================
  resources :ingredients  # Global ingredient catalog shared across all restaurants
  
  # ============================================================================
  # SMART MENU SYSTEM
  # ============================================================================
  resources :smartmenus
  patch 'smartmenus/:smartmenu_id/locale', to: 'smartmenus_locale#update', as: :smartmenu_locale
  
  # ============================================================================
  # OCR ENDPOINTS (Legacy/Direct Access)
  # ============================================================================
  resources :ocr_menu_items, only: [:update]
  resources :ocr_menu_sections, only: [:update]
  
  # ============================================================================
  # ANALYTICS AND REPORTING
  # ============================================================================
  resources :metrics
  resources :dw_orders_mv, only: [:index, :show]
  
  # Admin analytics dashboard
  namespace :admin do
    resources :metrics, only: [:index, :show] do
      collection do
        get :export
      end
    end
  end
  
  # ============================================================================
  # AUTHENTICATION INTEGRATIONS
  # ============================================================================
  get 'auth/spotify', to: 'restaurants#spotify_auth'
  get 'auth/spotify/callback', to: 'restaurants#spotify_callback'
  delete 'logout', to: 'restaurants#logout'
  
  # ============================================================================
  # ADMIN TOOLS (Protected)
  # ============================================================================
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    mount ActionCable.server => "/cable"
    
    draw :madmin
    
    namespace :madmin do
      resources :impersonates do
        post :impersonate, on: :member
        post :stop_impersonating, on: :collection
      end
    end
  end
end

