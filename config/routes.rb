Rails.application.routes.draw do
  root to: 'instruments#root'

  get '/instruments/:instrument_id/candles', to: 'candles#index', constraints: { instrument_id: /[^\/]+/ }

  resources :instruments do
    resources :candles, only: :index
    get :export, on: :collection
  end
  resources :insider_transactions, path: 'insider-transactions'
  resources :insider_aggregates, path: 'insider-aggregates'
  resources :insider_summaries, path: 'insider-summaries'
  resources :recommendations
  resources :signals
  resources :signal_results
  resources :signal_strategies
  resources :public_signals
  resources :portfolio, as: :portfolio_items
  resources :level_hits
  resource :comparision
end
