# Below are the routes for madmin
namespace :madmin do
  namespace :active_storage do
    resources :attachments
  end
  namespace :active_storage do
    resources :blobs
  end
  resources :announcements
  resources :services
  namespace :active_storage do
    resources :variant_records
  end
  namespace :noticed do
    resources :events
  end
  resources :users
  namespace :noticed do
    resources :notifications
  end
  root to: "dashboard#show"
end
