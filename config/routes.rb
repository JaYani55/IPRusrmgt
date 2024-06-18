Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'sessions', registrations: 'registrations' }

  # Define your root route
  root to: 'home#index'

  # RESTful routes for user profiles
  resources :users, only: [:show, :edit, :update]

  # Custom route for logout within devise_scope
  devise_scope :user do
    get 'logout', to: 'sessions#destroy', as: :logout
  end

  # Other routes can go here
end
