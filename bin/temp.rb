InsiderTransaction.find_each.select { |tx| tx.instrument == nil }.map(&:ticker)

/comparision?tickers=DK+FANG+CLR&base_date=2021-05-20&start_date=2021-05-01
