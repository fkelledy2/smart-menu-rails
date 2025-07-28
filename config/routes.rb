require 'sidekiq/web'

Rails.application.routes.draw do
  resources :testimonials
  resources :userplans
  resources :menuparticipants
  resources :contacts, only: [:new, :create]
  resources :features_plans
  resources :features
  resources :plans
  resources :restaurantlocales
  resources :tracks
  resources :smartmenus
  patch 'smartmenus/:smartmenu_id/locale', to: 'smartmenus_locale#update', as: :smartmenu_locale
  resources :genimages
  resources :metrics
  resources :tips
  resources :ordractions
  resources :restaurantavailabilities
  resources :menuavailabilities
  resources :ordrparticipants
  resources :inventories
  resources :ingredients
  resources :sizes
  resources :taxes
  resources :ordritemnotes
  resources :ordritems
  resources :ordrs
  resources :employees
  resources :tags
  resources :allergyns
  resources :menuitems
  resources :menusections
  resources :menuitemlocales
  resources :menusectionlocales
  resources :menulocales
  resources :tablesettings
  resources :menuitem_size_mappings, controller: 'menuitemsizemappings', only: [:update]

  resources :dw_orders_mv, only: [:index, :show]

  # Google Vision API endpoints
  namespace :api do
    namespace :v1 do
      post 'vision/analyze', to: 'vision#analyze'
      post 'vision/detect_menu_items', to: 'vision#detect_menu_items'
    end
  end

  resources :restaurants do
    resources :restaurantlocales, controller: 'restaurantlocales', only: [:index,:show, :edit, :delete]
    resources :menus, controller: 'menus', only: [:index,:show, :edit]
    resources :tablesettings, controller: 'tablesettings', only: [:index,:show, :edit]
    resources :taxes, controller: 'taxes', only: [:index,:show, :edit]
    resources :sizes, controller: 'sizes', only: [:index,:show, :edit]
    resources :tips, controller: 'tips', only: [:index,:show, :edit]
    resources :employees, controller: 'employees', only: [:index,:show, :edit]
    resources :restaurantavailabilities, controller: 'restaurantavailabilities', only: [:index,:show, :edit]
    resources :ordrs, controller: 'ordrs', only: [:index]
    resources :allergyns, controller: 'allergyns', only: [:index]
    resources :tracks, controller: 'tracks', only: [:index]
  end
  resources :menus, controller: 'menus' do
      resources :menusections, controller: 'menusections', only: [:index,:show, :edit]
      resources :menuavailabilities, controller: 'menuavailabilities', only: [:index,:show, :edit]
      resources :tablesettings, controller: 'menus', only: [:show]
      resources :menuitems, controller: 'menuitems', only: [:index,:show, :edit]
  end
  resources :menusections, controller: 'menusections' do
    resources :menuitems, controller: 'menuitems', only: [:index,:show, :edit]
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
  root to: 'home#index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
