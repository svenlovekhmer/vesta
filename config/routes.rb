Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check
  root to: "dashboard#index"
  resources :missions, only: [:index, :new, :create, :show]
  resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    member do
      get :confirm_destroy
    end
  end
  resource :profile, only: [:edit, :update]
end
