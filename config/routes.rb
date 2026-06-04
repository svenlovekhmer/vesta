Rails.application.routes.draw do
  devise_for :users,
    controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  root to: "pages#home"
  get "dashboard", to: "dashboard#index", as: :dashboard
  resources :missions, only: [:index, :new, :create, :show, :destroy]
  resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    member do
      get :confirm_destroy
      post :sync_emails
    end
  end
  resource :profile, only: [:edit, :update]
  resources :steps, only: [:update]
  resources :mission_step_blockers, only: [:create, :destroy]
  resources :decision_logs, only: [:update, :destroy] do
    member do
      get  :resolve_modal
      patch :resolve
    end
  end
end
