namespace :levels do
  envtask(:import) { PriceLevel.load_manual }
  envtask(:hits) { PriceLevelHit.analyze_manual }
  envtask(:hits_week) { PriceLevelHit.analyze_dates MarketCalendar.open_days(1.week.ago, Current.yesterday) }
  envtask(:hits_all) { PriceLevelHit.analyze_all }
  envtask(:search) { PriceLevel.search_all }
end

envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) { PublicSignal.parse_seeking_alpha; InsiderAggregate.aggregate }
