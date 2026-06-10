Rails.application.routes.draw do
  devise_for :users,
    controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  root to: "pages#home"
  get "dashboard", to: "dashboard#index", as: :dashboard
  resources :missions, only: [:index, :new, :create, :show, :update, :destroy] do
    resources :documents, only: [:create]
    collection do
      post :sync_all
    end
    member do
      get :confirm_destroy
    end
  end
  get "/portal/:token", to: "portals#show", as: :mission_portal
  resources :clients, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    member do
      get :confirm_destroy
      post :sync_emails
    end
  end
  resource :profile, only: [:edit, :update]
  resources :steps, only: [:update]
  resources :documents, only: [:destroy]
  resources :mission_step_blockers, only: [:create, :destroy]
  resources :decision_logs, only: [:update, :destroy, :create] do
    collection do
      get :new_modal
    end
    member do
      get  :resolve_modal
      patch :resolve
      get :confirm_destroy
      get :link_step_modal
      get :add_document_modal
    end
  end
  resources :decision_log_documents, only: [:create]
  resources :step_templates, except: [:show] do
    member do
      get :confirm_destroy
    end
  end
end
