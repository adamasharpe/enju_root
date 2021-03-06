EnjuRoot::Application.routes.draw do
  devise_for :users, :path => 'accounts'

  resource :my_account

  resources :produce_types

  resources :realize_types

  resources :create_types

  resources :event_import_results

  resources :patron_import_results

  resources :resource_import_results

  resources :patrons do
    resources :works
    resources :expressions
    resources :manifestations
    resources :items
    resources :picture_files
    resources :resources
    resources :patrons
    resources :patron_merges
    resources :patron_merge_lists
    resources :patron_relationships
    resources :creates
    resources :realizes
    resources :produces
    resources :owns
  end

  resources :works do
    resources :patrons
    resources :creates
    resources :subjects
    resources :work_has_subjects
    resources :expressions
    resources :work_relationships
    resources :works
    resources :reifies
  end

  resources :expressions do
    resources :patrons
    resources :realizes
    resources :manifestations
    resources :expression_relationships
    resources :expressions
    resources :reifies
    resources :embodies
    resource :work
  end

  resources :manifestations do
    resources :produces
    resources :patrons
    resources :items
    resources :picture_files
    resources :expressions
    resources :manifestation_relationships
    resources :manifestations
    resources :embodies
    resources :exemplifies
  end

  resources :creators, :controller => 'patrons' do
    resources :works
  end

  resources :contributors, :controller => 'patrons' do
    resources :expressions
  end

  resources :publishers, :controller => 'patrons' do
    resources :manifestations
  end

  resources :users do
  #  resource :patron
  end

  resources :patron_relationship_types
  resources :work_relationship_types
  resources :expression_relationship_types
  resources :manifestation_relationship_types
  resources :item_relationship_types
  resources :licenses
  resources :medium_of_performances
  resources :extents
  resources :request_status_types
  resources :request_types
  resources :frequencies
  resources :use_restrictions
  resources :item_has_use_restrictions
  resources :patron_types
  resources :circulation_statuses
  resources :form_of_works
  resources :patron_merge_lists do
    resources :patrons
  end
  resources :patron_merges
  resources :work_merges
  resources :work_merge_lists do
    resources :works
  end
  resources :expression_merges
  resources :expression_merge_lists do
    resources :expressions
  end

  resources :work_to_expression_rel_types

  resources :donates
  resources :subscriptions do
    resources :works
  end

  resources :subscribes
  resources :picture_files
  resources :series_statements do
    resources :manifestations
  end
  resources :search_histories

  resources :resource_import_files

  resources :patron_import_files

  resources :event_import_files

  resources :patron_relationships
  resources :work_relationships
  resources :expression_relationships
  resources :manifestation_relationships
  resources :item_relationships

  resources :bookstores

  resources :user_has_roles

  resources :roles

  resources :library_groups

  resources :search_engines

  resources :content_types

  resources :carrier_types

  resources :user_groups

  resources :shelves do
    resources :picture_files
  end

  resources :libraries do
    resources :shelves
  end

  resources :countries

  resources :languages

  resources :items do
    resources :item_has_use_restrictions
    resources :patrons
    resources :items
    resource :exemplify
  end

  resources :owns
  resources :produces
  resources :realizes
  resources :creates
  resources :exemplifies
  resources :embodies
  resources :reifies

  resources :import_requests

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "page#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  match '/isbn/:isbn' => 'manifestations#show'
  match '/calendar(/:year(/:month))' => 'calendar#index', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/}
  match "/calendar/:year/:month/:day" => "calendar#show"
  match '/page/about' => 'page#about'
  match '/page/configuration' => 'page#configuration'
  match '/page/advanced_search' => 'page#advanced_search'
  match '/page/add_on' => 'page#add_on'
  match '/page/export' => 'page#export'
  match '/page/import' => 'page#import'
  match '/page/msie_acceralator' => 'page#msie_acceralator'
  match '/page/opensearch' => 'page#opensearch'
  match '/page/statistics' => 'page#statistics'
  match '/page/routing_error' => 'page#routing_error'
  match '/sru/index' => 'sru#index'
end
