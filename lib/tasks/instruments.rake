namespace :instruments do
  envtask :remove do
    Instrument[ENV['ticker']].destroy!
  end
end
