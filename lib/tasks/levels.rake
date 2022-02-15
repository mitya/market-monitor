namespace :levels do
  envtask(:search)      { PriceLevelDetector.search_all }
  envtask(:import)      { PriceLevelDetector.load_manual }
  envtask(:hits_all)    { PriceLevelHitDetector.analyze_all }
  envtask(:hits_manual) { PriceLevelHitDetector.analyze_manual }
  envtask(:hits_week)   { PriceLevelHitDetector.analyze_dates MarketCalendar.open_days(1.week.ago, Current.yesterday) }
end

envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) { PublicSignal.parse_seeking_alpha; InsiderAggregate.aggregate }
