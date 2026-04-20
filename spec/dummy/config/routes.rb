# frozen_string_literal: true

Rails.application.routes.draw do
  resources :cryptids, only: [:index]
  resources :users, only: [:index]
  root to: "cryptids#index"
end
