Rails.application.routes.draw do
  root to: 'instruments#root'
  resources :instruments
  resources :insider_transactions, path: 'insider-transactions'
  resources :recommendations
  resources :portfolio, as: :portfolio_items
end
