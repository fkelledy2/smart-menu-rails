require 'sidekiq/web'

Rails.application.routes.draw do
  resources :tracks
  resources :smartmenus
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
  resources :tablesettings
  resources :menuitem_size_mappings, controller: 'menuitemsizemappings', only: [:update]

  resources :restaurants do
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
  draw :madmin
  get '/privacy', to: 'home#privacy'
  get '/terms', to: 'home#terms'
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
