Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'welcome#index'
  match '/user_login' => 'welcome#user_login', :via => [:get, :post]
  match '/signup' => 'welcome#signup', :as => :signup, :via => [:get, :post]
  post '/add_user' => 'welcome#add_user', :as => :add_user
  get '/login' => 'welcome#login', :as => :login
  get '/logout' => 'welcome#logout', :as => :logout

  resources :users
  match '/forgot' => 'users#forgot', :as => :forgot, :via => [:get, :post]
  match 'reset/:reset_code' => 'users#reset', :as => :reset, :via => [:get, :post]

   # Routes for physical source samples
  resources :samples do
    collection do
      get :auto_complete_for_barcode_key
    end
  end

  resources :sample_locs, :only => [:edit, :update]

  resources :sample_queries, :only => :index


   # Routes for extracted samples
  get 'processed_samples/autocomplete_processed_sample_barcode_search'
  resources :processed_samples do
    collection do
      #get :auto_complete_for_barcode_key
    end
  end

end
