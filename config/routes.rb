Rails.application.routes.draw do
  root to: 'instruments#root'

  get '/instruments/:instrument_id/candles', to: 'candles#index', constraints: { instrument_id: /[^\/]+/ }

  resources :instruments do
    resources :candles, only: :index
    resources :options, only: [:index, :show] do
      get :history, on: :member
    end
    get :export, :spb, :grouped, on: :collection
  end
  resources :insider_transactions, path: 'insider-transactions'
  resources :insider_aggregates, path: 'insider-aggregates'
  resources :insider_summaries, path: 'insider-summaries'
  resources :recommendations
  resources :spikes, only: %i[index]
  resources :signals do
    get :intraday, on: :collection
  end
  resources :signal_results
  resources :signal_strategies
  resources :public_signals
  resources :portfolio, as: :portfolio_items
  resources :level_hits
  resources :arbitrages, only: %i[index] do
    post :limit_order, :cancel_order, on: :collection
  end
  resources :orders, only: %i[index]
  resources :operations, only: %i[index]
  resource :trading, only: %i[], controller: :trading do
    get :dashboard
    get :activities
    get :candles, :charts, :recent, :momentum_ru, :momentum_us, :last_week, :last_week_spikes, :averages
    post :update_chart_settings, :update_intraday_levels, :update_ticker_sets, :refresh
  end
  resource :comparision
  resource :set_comparision  do
    get :summary
  end
  resources :news
  resources :futures do
    get :imported, on: :collection
  end

  mount ActionCable.server => '/cable'

  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql" if Rails.env.development?
  post "/graphql", to: "graphql#execute"
end
