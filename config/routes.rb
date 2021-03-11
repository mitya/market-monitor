Rails.application.routes.draw do
  root to: 'instruments#root'
  resources :instruments
end
