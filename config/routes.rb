require 'sidekiq/web'

Rails.application.routes.draw do
  # Onboarding wizard
  get 'onboarding', to: 'onboarding#show'
  get 'onboarding/step/:step', to: 'onboarding#show', as: :onboarding_step
  patch 'onboarding', to: 'onboarding#update'
  post 'onboarding', to: 'onboarding#update'
  resources :testimonials
  resources :userplans
  resources :contacts, only: [:new, :create]
  resources :features_plans
  resources :features
  resources :plans
  resources :metrics
  
  # Admin metrics dashboard
  namespace :admin do
    resources :metrics, only: [:index, :show] do
      collection do
        get :export
      end
    end
  end

  resources :smartmenus
  patch 'smartmenus/:smartmenu_id/locale', to: 'smartmenus_locale#update', as: :smartmenu_locale

  resources :genimages

  resources :ingredients

  resources :dw_orders_mv, only: [:index, :show]

  # Google Vision API endpoints - MUST come before non-API routes for proper precedence
  namespace :api do
    namespace :v1 do
      get 'test/ping', to: 'test#ping'
      post 'vision/analyze', to: 'vision#analyze'
      post 'vision/detect_menu_items', to: 'vision#detect_menu_items'
      resources :ocr_menu_items, only: [:update]
      resources :ocr_menu_sections, only: [:update]
      
      # Analytics tracking endpoints
      post 'analytics/track', to: 'analytics#track'
      post 'analytics/track_anonymous', to: 'analytics#track_anonymous'
    end
  end

  # Endpoint to update OCR menu items from modal
  resources :ocr_menu_items, only: [:update]

  # Endpoint to update OCR menu sections (inline title editing)
  resources :ocr_menu_sections, only: [:update]

  resources :restaurants do
    resources :restaurantlocales
    resources :menus, only: [:index, :show, :edit]
    resources :tablesettings
    resources :taxes
    resources :sizes
    resources :tips
    resources :employees
    resources :tags
    resources :allergyns
    resources :restaurantavailabilities
    resources :inventories
    resources :ordrs
    resources :ordritems
    resources :ordritemnotes
    resources :ordrparticipants
    resources :ordractions
    resources :tracks
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
  resources :menus do
    resources :menuparticipants
    resources :menuavailabilities
    resources :menusections do
      resources :menuitems  # Full CRUD including index for menusection-specific menuitems
    end
    resources :menusectionlocales
    resources :menuitem_size_mappings, controller: 'menuitemsizemappings', only: [:update]
    
    # Menu-level menuitems for bulk operations (index only)
    resources :menuitems, only: [:index]
    
    member do
      post :regenerate_images
      get :tablesettings, to: 'menus#show'  # More explicit than nested resource
    end
  end
  post "/create_payment_link", to: "payments#create_payment_link"
  post "/generate_qr", to: "payments#generate_qr"

  draw :madmin
  get '/privacy', to: 'home#privacy'
  get '/terms', to: 'home#terms'

  get 'auth/spotify', to: 'restaurants#spotify_auth'
  get 'auth/spotify/callback', to: 'restaurants#spotify_callback'
  delete 'logout', to: 'restaurants#logout'

authenticate :user, lambda { |u| u.admin? } do
  mount Sidekiq::Web => '/sidekiq'
  mount ActionCable.server => "/cable"

  namespace :madmin do
    resources :impersonates do
      post :impersonate, on: :member
      post :stop_impersonating, on: :collection
    end
  end
end

  resources :notifications, only: [:index]
  resources :announcements, only: [:index]
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  root to: "home#index", defaults: { format: :html }

  # Handle Chrome DevTools request
  get '/.well-known/appspecific/com.chrome.devtools.json', to: proc { [204, {}, ['']] }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end

