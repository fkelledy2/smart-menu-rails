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
  get '/offline', to: 'application#offline'
  
  # ============================================================================
  # HEALTH AND MONITORING
  # ============================================================================
  get "up" => "rails/health#show", as: :rails_health_check
  get '/.well-known/appspecific/com.chrome.devtools.json', to: proc { [204, {}, ['']] }
  
  # Cache and system health checks
  get '/health', to: 'health#index'
  get '/health/redis', to: 'health#redis_check'
  get '/health/database', to: 'health#database_check'
  get '/health/full', to: 'health#full_check'
  get '/health/cache-stats', to: 'health#cache_stats'
  
  # ============================================================================
  # API DOCUMENTATION (Development/Test only)
  # ============================================================================
  if Rails.env.development? || Rails.env.test?
    mount Rswag::Ui::Engine => '/api-docs'
    mount Rswag::Api::Engine => '/api-docs'
  end
  
  # ============================================================================
  # API ENDPOINTS
  # ============================================================================
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Test endpoints
      get 'test/ping', to: 'test#ping'
      
      # Restaurant Management API
      resources :restaurants, only: [:index, :show, :create, :update, :destroy] do
        # Restaurant-specific menus
        resources :menus, only: [:index, :create]
        
        # Restaurant-specific orders
        resources :orders, only: [:index, :create]
      end
      
      # Menu Management API
      resources :menus, only: [:show, :update, :destroy] do
        # Menu items
        resources :items, only: [:index], controller: 'menu_items'
      end
      
      # Order Management API
      resources :orders, only: [:show, :update, :destroy]
      
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
  
  # Push notification subscriptions
  resources :push_subscriptions, only: [:create, :destroy] do
    collection do
      post :test
    end
  end
  
  # ============================================================================
  # SUBSCRIPTION AND BILLING
  # ============================================================================
  resources :plans
  resources :features
  resources :features_plans
  resources :userplans
  resources :testimonials
  resources :hero_images
  resources :hero_images do
    collection do
      post :clear_cache
    end
  end
  
  # Payment processing (secure namespace)
  namespace :payments do
    post :create_payment_link, controller: 'base'
    post :generate_qr, controller: 'base'
    post :create_intent, to: 'intents#create'
  end
  
  # ============================================================================
  # RESTAURANT MANAGEMENT
  # ============================================================================
  resources :restaurants do
    # Kitchen Dashboard
    member do
      get 'kitchen', to: 'kitchen_dashboard#index', as: :kitchen_dashboard
      get 'bar', to: 'bar_dashboard#index', as: :bar_dashboard
      patch 'update_hours', to: 'restaurants#update_hours'
      patch 'update_alcohol_policy', to: 'restaurants#update_alcohol_policy'
      get 'alcohol_status', to: 'restaurants#alcohol_status'

      # Analytics for Ordering dashboard (JSON)
      get 'analytics/kpis',               to: 'restaurant_analytics#kpis'
      get 'analytics/timeseries',         to: 'restaurant_analytics#timeseries'
      get 'analytics/menu_mix',           to: 'restaurant_analytics#menu_mix'
      get 'analytics/top_items',          to: 'restaurant_analytics#top_items'
      get 'analytics/staff_performance',  to: 'restaurant_analytics#staff_performance'
      get 'analytics/table_performance',  to: 'restaurant_analytics#table_performance'
      get 'analytics/orders',             to: 'restaurant_analytics#orders'
      get 'analytics/items',              to: 'restaurant_analytics#items'
    end
    
    # Restaurant configuration
    resources :restaurantlocales do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :tablesettings do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :restaurantavailabilities
    
    # Restaurant catalog management
    resources :taxes do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :sizes do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :tips do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :tags
    resources :allergyns do
      collection do
        patch :bulk_update
        patch :reorder
      end
    end
    resources :genimages
    
    # Staff management
    resources :employees do
      collection do
        patch :bulk_update
        patch :reorder
      end
      member do
        get :analytics
      end
    end
    
    # Inventory management
    resources :inventories
    
    # Order management
    resources :ordrs do
      member do
        get :analytics
        post :ack_alcohol, to: 'ordrs#ack_alcohol'
      end
    end
    resources :ordr_station_tickets, only: [:update]
    resources :alcohol_order_events, only: [:index]
    resources :ordritems
    resources :ordritemnotes
    resources :ordrparticipants
    resources :ordractions
    
    # Music/Entertainment
    resources :tracks
    
    # Restaurant analytics endpoints
    member do
      get :analytics
      get :performance
    end
    
    # Restaurant summary endpoints
    collection do
      get 'employees/summary', to: 'employees#summary'
      get 'orders/summary', to: 'ordrs#summary'
    end
    
    # Menu management (full operations within restaurant context)
    resources :restaurant_menus, only: [] do
      collection do
        patch :reorder
        patch :bulk_update
        patch :bulk_availability
      end
      member do
        patch :availability
      end
    end

    resources :menus do
      member do
        post :attach
        post :share
        delete :detach
      end
      collection do
        patch :update_sequence
        patch :bulk_update
      end
      
      # Menu configuration
      resources :menuparticipants
      resources :menuavailabilities
      
      # Menu structure and content
      resources :menusections do
        collection do
          patch :reorder
        end
        
        resources :menuitems do  # Full CRUD for menusection-specific menuitems
          collection do
            patch :reorder
          end
          
          member do
            get :analytics
            post :generate_ai_image
            get :image_status
          end
        end
      end
      
      # Menu-level menuitem operations
      resources :menuitems, only: [:index]  # Bulk operations across all menusections
      resources :menuitem_size_mappings, controller: 'menuitemsizemappings', only: [:update]
      
      # Menu actions and analytics
      member do
        post :regenerate_images
        get :image_generation_progress
        get :localization_progress
        post :polish, to: 'menus#polish'
        get :polish_progress, to: 'menus#polish_progress'
        post :localize
        patch :update_availabilities
        get :tablesettings, to: 'menus#show'
        get :analytics
        get :performance
      end
    end
    
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
  # GLOBAL RESOURCES
  # ============================================================================
  resources :ingredients  # Global ingredient catalog shared across all restaurants
  
  # Direct ordrparticipant updates (for frontend compatibility)
  resources :ordrparticipants, only: [:update]
  
  # ============================================================================
  # SMART MENU SYSTEM
  # ============================================================================
  resources :smartmenus do
    resources :voice_commands, only: %i[create show], controller: 'smartmenus_voice_commands'
  end
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
  
  # Global menuitem analytics (direct access)
  resources :menuitems, only: [] do
    member do
      get :analytics
    end
  end
  
  # Performance Analytics (APM)
  resources :performance_analytics, only: [] do
    collection do
      get :dashboard
      get :api_metrics
      get :endpoint_analysis
      get :slow_queries
      get :memory_analysis
      get :performance_summary
      get :export_metrics
    end
  end
  
  # Admin analytics dashboard
  namespace :admin do
    resources :metrics, only: [:index, :show] do
      collection do
        get :export
      end
    end
    
    # Performance monitoring
    resources :performance, only: [:index] do
      collection do
        get :requests
        get :queries
        get :cache
        get :memory
        post :reset
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
    
    # Cache administration
    namespace :admin do
      resources :cache, only: [:index] do
        collection do
          get :stats
          post :warm
          delete :clear
          post :reset_stats
          get :health
          get :keys
        end
      end

      resources :menu_item_search, only: [:index] do
        collection do
          post :reindex
        end
      end
    end
  end
end

