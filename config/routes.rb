Rails.application.routes.draw do
  root to: 'instruments#root'

  get '/instruments/:instrument_id/candles', to: 'candles#index', constraints: { instrument_id: /[^\/]+/ }

  resources :instruments do
    resources :candles, only: :index
  end
  resources :insider_transactions, path: 'insider-transactions'
  resources :insider_aggregates, path: 'insider-aggregates'
  resources :recommendations
  resources :signals
  resources :public_signals
  resources :portfolio, as: :portfolio_items
  resources :level_hits
end
