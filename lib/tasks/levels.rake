envtask('levels:import') { PriceLevel.load_manual }
envtask('levels:hits') { PriceLevelHit.analyze_manual }
envtask('levels:hits:week') { PriceLevelHit.analyze_dates MarketCalendar.open_days(1.week.ago, Current.yesterday) }
envtask('levels:hits:all') { PriceLevelHit.analyze_all }
envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) {
  PublicSignal.parse_seeking_alpha
  InsiderAggregate.aggregate
}

envtask(:levels) { PriceLevel.search_all }
