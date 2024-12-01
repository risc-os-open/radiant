Rails.application.routes.draw do

  # Admin RESTful routes
  #
  namespace :admin do
    resources :pages do
      get 'remove', on: :member
      resources :children, controller: "pages"
    end

    post 'preview', to: 'pages#preview'
    put  'preview', to: 'pages#preview'

    resources(:layouts ) { get 'remove', on: :member }
    resources(:snippets) { get 'remove', on: :member }
    resources(:users   ) { get 'remove', on: :member }

    resource :preferences, only: [ :edit, :update ]
    resource :configuration, controller: 'configuration'

    resources :page_parts
    resources :page_fields

    get '/reference/:type', as: 'reference', to: 'references#show'

    get  '/',        as: '',        to: 'welcome#index'
    get  '/welcome', as: 'welcome', to: 'welcome#index'
    get  '/login',   as: 'login',   to: 'welcome#login'
    post '/login',                  to: 'welcome#login'
    get  '/logout',  as: 'logout',  to: 'welcome#logout'
  end

  # Site URLs
  #
  root                               to: 'site#show_page', url: '/'
  get  'error/404', as: 'not_found', to: 'site#not_found'
  get  'error/500', as: 'error',     to: 'site#error'
  get  '*url',                       to: 'site#show_page'

end
