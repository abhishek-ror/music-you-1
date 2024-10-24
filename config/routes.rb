Rails.application.routes.draw do
  get "/healthcheck", to: proc { [200, {}, ["Ok"]] }
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  namespace :bx_block_login do
    resources :logins, only: [:create] do
      collection do
        post :verify_otp
      end
    end
    resource :logouts, only: [:destroy]
  end

  namespace :account_block do
    resources :accounts, only: [:create] do
      collection do
        post :verify_otp
        put :update_account
        put :change_email_address
        # post :resend_otp
        get :safeties
        get :about
        get :help
      end
    end
  end

  get '/account-deletion-steps', to: 'account_block/accounts#account_deletion_steps'

  namespace :bx_block_terms_and_conditions do
    resources :terms_and_conditions, only: [:index, :show, :create] do
      collection do
        get 'latest_record'
      end
    end
  end

  get '/terms-and-conditions', to: 'bx_block_terms_and_conditions/terms_and_conditions#terms_and_condtions_data'

  get '/privacy-policy', to: 'bx_block_terms_and_conditions/terms_and_conditions#privacy_policy'

  namespace :bx_block_apple_login do
    post '/validate_apple_login', to: 'apple_accounts#validate'
  end

  namespace :bx_block_profile do
    resources :profiles, only: [:create, :show, :update, :destroy] do
      collection do
        get :custom_user_profile_fields
        post :custom_user_profile_fields
        get :matching_profiles
        put :update_user_profile
        get :get_user_profile
        get :get_favorite_artists
        get :profile_songs
        post :add_gym_songs
        post :add_love_songs
        post :add_wedding_songs
      end
    end

    resource :password, only: [:update]
  end

  namespace :bx_block_forgot_password do
    resource :otp_confirmations
    resource :otps
    resource :passwords, only: [:create] do
      post :change_password, on: :collection
    end
  end

  namespace :bx_block_comments do
    resources :comments do
      post :like, on: :member
    end
  end

  namespace :bx_block_like do
    resources :likes do
      collection do
        get :mutual_likes
        post :unlike
      end
    end
  end

  namespace :bx_block_posts do
    resources :posts, only: [:index, :create, :update]
  end

  namespace :bx_block_like_a_post do
    resources :like_posts
  end

  namespace :bx_block_push_notifications do
    resources :push_notifications
  end

  namespace :bx_block_privacy_setting do
    resources :privacy_settings, only: [:index, :create, :update] do
      collection do
        get 'user_privacy_settings'
        put 'update_settings'
      end
    end
  end

  namespace :bx_block_stripe_integration do
    resources :payment_methods, only: [:index, :create]
  end

  namespace :bx_block_chat do
    resources :chats, only: [:index, :show, :create, :update] do
      collection do
        get :history
        get :search
        get :search_messages
        get :unread_messages
        get :unread_messages_count
      end
      member do
        get :read_messages
        post :block_user
        post :unblock_user
        post :report_user
      end

      resources :messages, only: [:index, :create]
      collection do
        get :all, to: 'messages#index_all'
      end
    end

    get 'messages/all', to: 'messages#index_all', as: 'all_messages'
  end

  namespace :bx_block_settings do
    resources :settings, only: [:index] do
      delete 'delete_account', on: :collection
    end
  end

  namespace :bx_block_notifsettings do
    resources :notification_settings, only: [:index, :update] do
    end
  end

  namespace :bx_block_favourites do
    resources :favourites, only: [] do
      get 'favourites_list', on: :collection
    end
  end

  namespace :bx_block_freecredits do
    resources :freecredit_balances, only: [] do
      get 'freecredit_balance', on: :collection
      post 'transation', on: :collection
    end
  end

  namespace :bx_block_filter_items do
    get 'filter_items', to: 'filtering#filter_items'
  end

  namespace :bx_block_location do
    resource :location, only: [] do
      collection do
        put :user_location
      end
    end
  end

  namespace :bx_block_communityforum do
    resources :posts, only: [:index, :create, :destroy, :update] do
      get :conversations_details, on: :collection
      get :sort_post_comments, on: :collection
    end
    resources :community_forums, only: [:create] do
      collection do
        post :invite_members
        post :join
      end
    end
  end

  namespace :bx_block_bulk_uploading do
    resources :attachments do
      delete :delete_attachment, on: :member
    end

    resources :audio_records, only: [:index, :create]
  end

  namespace :bx_block_photo_library do
    resources :photo_libraries, only: [:index, :create]
  end

  namespace :bx_block_apiintegration52 do
    resources :music_connections, only: [:create, :index] do
      collection do
        get :get_synced_users
        delete :unsync
      end
    end
  end

  namespace :bx_block_audiomusic2 do
    resources :tracks, only: [:index, :show, :create] do
      member do
        put :play
        put :pause
      end

      collection do
        get :get_currently_playing_track
        get :currently_playing
        get :recently_added_tracks
      end
    end
  end

  namespace :bx_block_content_moderation do
    resources :moderations, only: [:index, :create]
  end

  namespace :bx_block_categories do
    resources :categories do
      collection do
        get :spotify_genres_list
        get :genres_category
        get :looking_for_you
        get :favourite_artists
        get :favorite_love_songs
        get :favorite_gym_songs
        get :all_info
        get :ethnicities
        get :community_forum_categories
      end
    end

    # patch '/update_user_categories', to: 'categories#update_user_categories'
    # patch '/update_user_sub_categories', to: 'sub_categories#update_user_sub_categories'
  end

  delete '/admin/categories/:category_id/sub_categories/:id', to: 'admin/categories#destroy_sub_category', as: 'admin_category_destroy_sub_category'

  namespace :bx_block_share do
    resources :share, only: [:create, :index] do
      collection do
        get :share_profile
        get :show_profile
        get :share_post
        get :show_post
        get :shared_with_me
        post :twitter
      end
    end
  end

  namespace :bx_block_invitefriends2 do
    resources :invite_friends, only: [:create]
    get 'redirect', to: 'invite_friends#redirect'
  end

  namespace :bx_block_email_notifications do
    resources :email_notifications, only: [:show, :create] do
      member do
        delete :unsubscribe
      end
    end
    put 'email_preferences', to: 'email_notifications#update_preferences'
  end


  namespace :bx_block_roles_permissions do
    resource :role, only: [:show]
  end

  namespace :bx_block_block_users do
    resources :block_users, only: [:index, :show, :create, :destroy]
  end

  namespace :admin do
    resources :block_users do
      member do
        post 'block'
        put 'unblock'
      end
    end
  end

  namespace :bx_block_user_status do
    resources :user_status, only: [:index] do
      collection do
        post :set_status
        get :check_status
      end
    end
  end

  namespace :bx_block_subscription_billing do
    resources :plans, only: [:index, :show]
    resources :recurring_subscriptions, only: [:create, :index, :update, :destroy]
  end

  namespace :bx_block_automatic_renewals do
    resources :automatic_renewals, only: [:create, :index, :show, :update, :destroy]
  end

  namespace :bx_block_events do
    resources :events do
      collection do
        post 'overlap_event'
        get 'fetch_ticketmaster_events'
        get 'event_details'
        get 'search_events'
        post 'mark_interested'
        get 'fetch_locations'
        get 'search_location'
      end
      member do
        post 'share'
        put 'notes_update'
      end
    end
  end

  namespace :admin do
    resources :admin_content_flags_path, as: 'content_flags', controller: 'admin_content_flags_path'
  end

  namespace :bx_block_contentflag do
    resources :contents, only: [:create, :index, :update] do
      collection do
        post :flag_comment
      end
    end
  end

  namespace :bx_block_search do
    resources :search do
      collection do
        get :songs
        get :search_song
        get :apple_music_search
        get :search_artists
      end
    end
  end

  namespace :bx_block_applemusicapiconnection do
    resources :apple_music_api_connections, only: [] do
      collection do
        get :developer_token
      end
    end
  end
end
