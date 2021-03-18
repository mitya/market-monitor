Rails.application.routes.draw do
  root to: 'instruments#root'
  resources :instruments
  resources :insider_transactions, path: 'insider-transactions'
end
