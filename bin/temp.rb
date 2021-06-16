InsiderTransaction.find_each.select { |tx| tx.instrument == nil }.map(&:ticker)
