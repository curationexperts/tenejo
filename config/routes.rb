# frozen_string_literal: true
require 'sidekiq/web'
Rails.application.routes.draw do
  resource :theme, only: [:edit, :update]
  resources :jobs,       only: [:index, :new, :show]
  resources :checks,       only: [:index]
  resources :preflights, only: [:index, :new, :create, :show]
  resources :imports,    only: [:index, :new, :create, :show]

  resource :dashboard, only: [:show], controller: 'tenejo/dashboard' do
    collection do
      get 'sidekiq'
    end
  end

  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?
  mount BrowseEverything::Engine => '/browse'

  mount Blacklight::Engine => '/'

  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end
  devise_for :users
  devise_scope  :users do
    put "activate", to: "users#activate"
  end
  mount Hydra::RoleManagement::Engine => '/'

  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#unhandled_exception', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  
  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
