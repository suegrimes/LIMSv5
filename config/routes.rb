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
    post 'add_new_sample', on: :member
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

  match 'upd_sample' => 'samples#edit_params', :as => :upd_sample, :via => [:get, :post]
  match 'edit_samples' => 'samples#edit_by_barcode', :as => :edit_samples, :via => [:get]

  resources :sample_locs, :only => [:edit, :update]

  # Routes for sample queries
  resources :sample_queries, :only => :index
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
  resources :molecular_assays do
    get :list_added, on: :collection
    post :create_assays, on: :collection
  end
  match 'populate_assays' => 'molecular_assays#populate_assays', :via => [:get, :post]
  #
  resources :molassay_queries, :only => :index
  get 'mol_assay_query' => 'molassay_queries#new_query'

  # Routes for patients
  resources :patients
  match 'modify_patient' => 'patients#edit_params', :as => :modify_patient, :via => [:get, :post]
  match 'encrypt_patient' => 'patients#loadtodb', :as => :encrypt_patient, :via => [:get, :post]

  # Routes for storage containers
  resources :storage_containers do
    get 'positions_used', on: :member
  end
  match 'export_container' => 'storage_containers#export_container', :as => :export_container, :via => [:post]
  get 'container_query' => 'storage_containers#new_query', :as => :container_query
  get 'container_contents' => 'storage_containers#list_contents', :as => :container_contents

  resources :sample_storage_containers, :only => [:edit, :update]

  # Routes for sample storage locations
  resources :sample_locs, :only => [:show, :edit, :update]
  resources :psample_locs, :only => [:show, :edit, :update]
  get 'sample_loc_query' => 'sample_loc_queries#new_query', :as => :sample_loc_query
  post 'export_sample_locs' => 'sample_loc_queries#export_samples', :as => :export_sample_locs
  resources :sample_loc_queries, :only => :index

  # Routes for sequencing libraries
  #get 'sequencing/main' => 'seq_libs#main_hdr'
  resources :seq_libs do
    get :get_adapter_info, on: :collection
   end
  post 'populate_libs' => 'seq_libs#populate_libs'

  resources :mplex_libs, :except => [:show, :index] do
    get :auto_complete_for_barcode_key, on: :collection
  end
  get 'mplex_setup' => 'mplex_libs#setup_params', :as => 'mplex_setup'

  # Routes for sequencing library queries
  resources :seqlib_queries, :only => :index
  get 'seqlib_query' => 'seqlib_queries#new_query'
  match 'export_seqlibs' => 'seqlib_queries#export_seqlibs', :as => :export_seqlibs, :via => :post

  # Routes for flow cells/sequencing runs
  #get 'flow_cells/autocomplete_flow_cells_sequencing_key'
  resources :flow_cells do
    get :auto_complete_for_sequencing_key, on: :collection
    get :show_publications, on: :member
    patch :upd_for_sequencing, on: :member
  end
  match 'flow_cell_setup' => 'flow_cells#setup_params', :as => :flow_cell_setup, :via => [:get, :post]

  # Routes for sequencing run queries
  resources :flowcell_queries, :only => :index
  get 'seq_run_query' => 'flowcell_queries#new_query'
  match 'export_seqruns' => 'flowcell_queries#export_seqruns', :as => :export_seqruns, :via => :post

  # Routes for handling file attachments
  resources :attached_files
  match 'attach_params' => 'attached_files#get_params', :as => :attach_params, :via => [:get, :post]
  match 'display_file/:id' => 'attached_files#show', :as => :display_file, :via => [:get]
  match 'attach_file' => 'attached_files#create', :via => [:get, :post]

  # Bulk upload
  get 'bulk_upload' => 'bulk_upload#new'
  post 'bulk_upload' => 'bulk_upload#create'

  # Routes for sequencing-related publications
  resources :publications
  get 'pub_lanes' => 'publications#populate_lanes', as: :pub_lanes

  # Routes for reserved barcodes
  resources :assigned_barcodes
  get 'check_barcodes/available' => 'assigned_barcodes#check_barcodes', :as => :check_available_barcodes, :rtype => 'available'
  get 'check_barcodes/assigned' => 'assigned_barcodes#check_barcodes', :as => :list_assigned_barcodes, :rtype => 'assigned'

  # Tables for dropdown lists
  resources :consent_protocols
  resources :protocols
  match 'select_protocol_type' => 'protocols#query_params', :as => :select_protocol_type, :via => [:get, :post]
  resources :categories
  resources :adapters
  resources :index_tags
  resources :oligo_pools, :only => :index
  resources :alignment_refs, :only => [:new, :create, :edit, :update, :index]
  resources :seq_machines
  resources :freezer_locations
  resources :storage_types
  resources :sequencer_kits
  resources :researchers

  # Routes for ordering chemicals & supplies
  resources :orders
  get 'edit_items' => 'orders#edit_order_items', :as => :edit_order_items
  get 'view_orders' => 'orders#new_query', :as => :view_orders
  match 'list_orders' => 'orders#list_selected', :as => :list_orders, :via => [:get, :post]

  #get 'items/autocomplete_item_company_name'
  #get 'items/autocomplete_item_item_description'
  #get 'items/autocomplete_item_catalog_nr'
  #post 'items/populate_items'
  resources :items do
    collection do
      get :autocomplete_for_item_description
      get :autocomplete_for_company_name
      get :autocomplete_for_catalog_nr
    end
  end

  get 'view_items' => 'items#new_query', :as => :view_items
  match 'list_items' => 'items#list_selected', :as => :list_items, :via => [:get, :post]
  get 'unordered_items' => 'items#list_unordered_items', :as => :notordered
  post 'export_items' => 'items#export_items', :as => :export_items
  post 'receive_items' => 'items#receive_items', :as => :receive_items
  match 'add_items' => 'items#populate_items', :as => :populate_items, :via => [:get, :post]

  # test route
  get 'test' => 'test#index'

end
