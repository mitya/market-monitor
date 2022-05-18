namespace :bugs do
  envtask :dup_dates do
    Instrument.find_each do |inst|
      total = inst.candles.pluck(:date).count
      uniq_total = inst.candles.distinct.pluck(:date).count
      if total != uniq_total
        diff = total - uniq_total
        dates = inst.candles.pluck(:date)
        dup_dates = dates.select { dates.count(_1) > 1 }.uniq.sort
        puts "#{inst.ticker}: #{diff} #{dup_dates.join(' ')}"

        inst.candles.where(date: dup_dates).group_by(&:date).each do |date, candles|
          # puts "#{inst.ticker} #{date} #{candles.count} #{candles[1..-1].size}"
          # candles[1..-1].each &:destroy
        end
      end
    end
  end
end

__END__

r bugs:dup_dates
