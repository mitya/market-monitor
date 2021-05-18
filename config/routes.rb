Rails.application.routes.draw do
  root to: 'instruments#root'
  resources :instruments
  resources :insider_transactions, path: 'insider-transactions'
  resources :recommendations
  resources :signals
  resources :public_signals
  resources :portfolio, as: :portfolio_items
end
