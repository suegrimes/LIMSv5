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

  # Routes for clinical samples/sample characteristics
  resources :sample_characteristics do
    get 'add_new_sample', on: :member
    post 'add_another_sample', on: :member
    post 'new_sample', on: :collection
  end
  resources :pathologies

  post 'patient_sample' => 'sample_characteristics#new_sample', :as => :add_pt_sample
  match 'modify_sample' => 'sample_characteristics#edit_params', :as => :modify_sample, :via => [:get, :post]
  post 'new_pathology' => 'pathologies#new_params', :as => :new_path_rpt

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

  # Routes for patients
  resources :patients
  match 'modify_patient' => 'patients#edit_params', :as => :modify_patient, :via => [:get, :post]
  match 'encrypt_patient' => 'patients#loadtodb', :as => :encrypt_patient, :via => [:get, :post]

end
