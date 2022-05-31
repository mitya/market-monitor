Rails.application.routes.draw do
  root to: 'dashboards#momentum'

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
  resources :orders, only: :index
  resources :operations, only: :index
  resources :news, only: :index
  resource :trading, only: [], controller: :trading do
    get :activities
    post :refresh
  end

  resource :dashboard, only: [] do
    get :momentum, :today, :favorites, :week, :week_spikes, :week_extremums, :averages, :timeline, :favorites, :minutes
  end

  resource :set_comparision, only: []  do
    get :static, :dynamic
  end

  resource :chart, only: %i[show update] do
    get :candles
    put :update_intraday_levels, :update_ticker_sets
  end

  resource :comparision, only: :show

  resources :futures, only: :index do
    get :imported, on: :collection
  end

  resources :ticker_sets, only: [] do
    resources :items, only: [:create, :destroy], controller: :ticker_set_items do
      post :toggle, on: :member
    end
  end

  resources :watched_targets, only: %i[index create destroy]

  mount ActionCable.server => '/cable'

  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql" if Rails.env.development?
  post "/graphql", to: "graphql#execute"
end
