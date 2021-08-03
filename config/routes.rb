Rails.application.routes.draw do
  root to: 'instruments#root'

  get '/instruments/:instrument_id/candles', to: 'candles#index', constraints: { instrument_id: /[^\/]+/ }

  resources :instruments do
    resources :candles, only: :index
    resources :options, only: [:index, :show] do
      get :history, on: :member
    end
    get :export, :spb, on: :collection
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
  resources :arbitrages, only: %i[index]
  resources :orders, only: %i[index]
  resources :operations, only: %i[index]
  resource :trading, only: %i[], controller: :trading do
    get :dashboard
  end
  resource :comparision
end
