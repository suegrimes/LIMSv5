Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'welcome#index'
  match '/user_login' => 'welcome#user_login', :via => [:get, :post]
  match '/signup' => 'welcome#signup', :as => :signup, :via => [:get, :post]
  post '/add_user' => 'welcome#add_user', :as => :add_user
  get '/login' => 'welcome#login', :as => :login
  get '/logout' => 'welcome#logout', :as => :logout

  # Reusable routing
  #concern :file_attachable do
  #  resources :attached_files, only: :index
  #end

  resources :users
  match '/forgot' => 'users#forgot', :as => :forgot, :via => [:get, :post]
  match 'reset/:reset_code' => 'users#reset', :as => :reset, :via => [:get, :post]

  # Routes for clinical samples/sample characteristics
  resources :sample_characteristics do
    get 'add_new_sample', on: :member
    post 'add_another_sample', on: :member
    post 'new_sample', on: :collection
  end

  post 'patient_sample' => 'sample_characteristics#new_sample', :as => :add_pt_sample
  match 'modify_sample' => 'sample_characteristics#edit_params', :as => :modify_sample, :via => [:get, :post]

  # Routes for pathology
  resources :pathologies
  get 'new_pathology' => 'pathologies#new_params', :as => :new_path_rpt

  # Routes for H&E slides
  resources :histologies do
    get :auto_complete_for_barcode_key, on: :collection
  end
  get 'new_histology' => 'histologies#new_params', :as => :new_he_slide

  resources :histology_queries, :only => :index
  get 'he_query' => 'histology_queries#new_query', :as => :he_query

  # Routes for physical source samples
  resources :samples do
    get :auto_complete_for_barcode_key, on: :collection
  end

  resources :sample_locs, :only => [:edit, :update]

  resources :sample_queries, :only => :index

  match 'upd_sample' => 'samples#edit_params', :as => :upd_sample, :via => [:get, :post]
  match 'edit_samples' => 'samples#edit_by_barcode', :as => :edit_samples, :via => [:get]
  match 'unprocessed_query' => 'sample_queries#new_query', :as => :unprocessed_query, :via => [:get]
  match 'samples_for_patient' => 'sample_queries#list_samples_for_patient', :as => :samples_list, :via => [:get]
  match 'samples_from_source' => 'sample_queries#list_samples_for_characteristic', :as => :samples_list1, :via => [:get]
  match 'export_samples' => 'sample_queries#export_samples', :as => :export_samples,  :via => [:post]

  get 'storage_query' => 'storage_queries#new_query', :as => :storage_query

   # Routes for dissected samples
  resources :dissected_samples do
    get 'add_multi', on: :member
    post 'create_multi', on: :member
  end
  match 'new_dissection' => 'dissected_samples#new_params', :as => :new_dissection, :via => [:get, :post]
  match 'add_dissection' => 'dissected_samples#new', :via => [:get, :post]

   # Routes for extracted samples
  get 'processed_samples/autocomplete_processed_sample_barcode_search'
  resources :processed_samples
  match 'new_extraction' => 'processed_samples#new_params', :as => :new_extraction, :via => [:get, :post]
  match 'add_extraction' => 'processed_samples#new', :via => [:get, :post]
  match 'edit_psamples' => 'processed_samples#edit_by_barcode', :as => :edit_psamples, :via => [:get, :post]
  match 'samples_processed' => 'processed_samples#show_by_sample', :as => :samples_processed, :via => [:get, :post]

  resources :psample_queries, :only => :index
  get 'processed_query' => 'psample_queries#new_query', :as => :processed_query
  match 'export_psamples' => 'psample_queries#export_samples', :as => :export_psamples, :via => [:post]

  # Routes for molecular assays
  get 'molecular_assays/autocomplete_molecular_assay_source_sample_name'
  get 'molecular_assays/main' => 'molecular_assays#main_hdr'
  resources :molecular_assays
  get 'create_molecular_assays' => 'molecular_assays#create_assays'
  match 'populate_assays' => 'molecular_assays#populate_assays', :via => [:get, :post]
  get 'molecular_assays/list_added' => 'molecular_assays#list_added'
  #match 'populate_assays/:nr_assays' => 'molecular_assays#populate_assays', :as => :populate_assays, :via => :get
  #
  resources :molassay_queries, :only => :index
  get 'mol_assay_query' => 'molassay_queries#new_query'

  # Routes for patients
  resources :patients
  match 'modify_patient' => 'patients#edit_params', :as => :modify_patient, :via => [:get, :post]
  match 'encrypt_patient' => 'patients#loadtodb', :as => :encrypt_patient, :via => [:get, :post]

  # routes for storage containers
  resources :storage_containers do
    get 'positions_used', on: :member
  end
  match 'export_container' => 'storage_containers#export_container', :as => :export_container, :via => [:post]

  resources :sample_storage_containers, :only => [:edit, :update]

  # Routes for handling file attachments
  resources :attached_files
  match 'attach_params' => 'attached_files#get_params', :as => :attach_params, :via => [:get, :post]
  match 'display_file/:id' => 'attached_files#show', :as => :display_file, :via => [:get]
  match 'attach_file' => 'attached_files#create', :via => [:get, :post]

  get 'container_query' => 'storage_containers#new_query', :as => :container_query
  get 'container_contents' => 'storage_containers#list_contents', :as => :container_contents

  # Bulk upload
  get 'bulk_upload' => 'bulk_upload#new'
  post 'bulk_upload' => 'bulk_upload#create'

  # Tables for dropdown lists
  resources :consent_protocols
  resources :protocols
  match 'select_protocol_type' => 'protocols#query_params', :as => :select_protocol_type, :via => [:get, :post]
  resources :categories
  resources :adapters
  resources :index_tags
  resources :alignment_refs, :only => [:new, :create, :edit, :update, :index]
  resources :seq_machines
  resources :freezer_locations
  resources :researchers

  # test route
  get 'test' => 'test#index'

end
