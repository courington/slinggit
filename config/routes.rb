SlinggitWebapp::Application.routes.draw do
  #ajax methods
  match 'users/set_no_thanks', :to => 'users#set_no_thanks', via: :get
  match 'users/reset_page_session', :to => 'users#reset_page_session', via: :get
  match 'users/verify_email_availability', :to => 'users#verify_email_availability', via: :post
  match 'networks/set_primary_account', :to => 'networks#set_primary_account', via: :post
  match 'networks/delete_account', :to => 'networks#delete_account', via: :post

  resources :users
  resources :sessions, only: [:new, :create, :destroy]
  resources :posts, only: [:new, :create, :destroy, :edit, :show, :update]
  resources :networks, only: [:index, :create, :destroy]

  match '/twitter_callback', :to => 'twittersessions#callback', :as => 'callback'
  match '/twitter_signup_callback', :to => 'users#twitter_signup_callback'
  match '/reauthorize_twitter', to: 'twittersessions#reauthorize'
  match '/create_reauthorization', to: 'twittersessions#create_reauthorization'
  match '/reauthorize_callback', to: 'twittersessions#reauthorize_callback'

  resources :twittersessions

  root to: 'static_pages#home'

  match '/signup', to: 'users#new'
  match '/signin', to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete

  match '/about', to: 'static_pages#about'
  match '/contact', to: 'static_pages#contact'

  # Nested route for comments.  I'm a bit worried that I'm defining resource :posts twice,
  # the other above, but couldn't find documentation on how to combine the two so that posts
  # can keep the only contraint.  Not entirely sure I'll need this yet.
  resources :posts do
    resources :comments
  end

  ##MOBILE CONTROLLER##
  post "mobile/user_signup"
  get "mobile/user_login"
  post "mobile/user_logout"
  post "mobile/user_login_status"
  post "mobile/get_user_twiiter_post_data"
  post "mobile/get_slinggit_twitter_post_data"
  post "mobile/get_user_api_accounts"
  post "mobile/create_twitter_post"
  post "mobile/delete_twitter_post"
  post "mobile/update_twitter_post"


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
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
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
  #       get 'recent', :on => :collection
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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
