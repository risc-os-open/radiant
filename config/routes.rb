Rails.application.routes.draw do

  # Admin RESTful routes
  #
  namespace :admin do
    # :member => { :remove => :get }    ==> get :remove --?

    resources :pages do
      resources :children, controller: "pages"
    end

    resources :layouts
    resources :users
  end

  post 'admin/preview', to: 'admin/pages#preview'
  put  'admin/preview', to: 'admin/pages#preview'

  namespace :admin do
    resource :preferences
    resource :configuration, controller: 'configuration'

    resources :extensions, only: :index
    resources :page_parts
    resources :page_fields

    get '/reference/:type.:format', as: 'reference', to: 'references#show'
  end

  # Admin other routes
  #
  get  'admin',         as: 'admin',   to: 'admin/welcome#index'
  get  'admin/welcome', as: 'welcome', to: 'admin/welcome#index'
  get  'admin/login',   as: 'login',   to: 'admin/welcome#login'
  post 'admin/login',                  to: 'admin/welcome#login'
  get  'admin/logout',  as: 'logout',  to: 'admin/welcome#logout'

  # Site URLs
  #
  root                               to: 'site#show_page', url: '/'
  get  'error/404', as: 'not_found', to: 'site#not_found'
  get  'error/500', as: 'error',     to: 'site#error'
  get  '*url',                       to: 'site#show_page'

end
