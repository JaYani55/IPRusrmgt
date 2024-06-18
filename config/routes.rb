Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }

  # Define your root route
  root to: 'home#index'

  # RESTful routes for user profiles
  resources :users, only: [:show, :edit, :update]

  # Custom route for logout
  get 'logout', to: 'sessions#destroy', as: :logout

  # Other routes can go here
end
