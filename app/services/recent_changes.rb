class RecentChanges
  include StaticService

  def prepare(instruments, periods: [60], now: Time.current)
    ApplicationRecord.benchmark "RecentChanges.prepare".magenta, silence: true do
      recent_gains = {}
      recent_losses = {}
      recent_changes = {}

      periods.each do |interval|
        recent_candles = Candle::M1.for(instruments).today.where(time: (now - interval.minutes).to_hhmm .. now.to_hhmm).order(:time).group_by(&:instrument)
        recent_candles.reject! { |inst, candles| candles.size < 5 }
        recent_gains[interval]  = recent_candles.map { |inst, candles| [inst.ticker, inst.gain_since(candles.minimum(:low),  :last)] }.to_h
        recent_losses[interval] = recent_candles.map { |inst, candles| [inst.ticker, inst.gain_since(candles.maximum(:high), :last)] }.to_h
        recent_changes[interval] = recent_candles.map do |inst, _|
          gain = recent_gains[interval][inst.ticker].to_f
          loss = recent_losses[interval][inst.ticker].to_f
          [inst.ticker, gain.abs > loss.abs ? gain : loss]
        end.to_h
      end

      [recent_gains, recent_losses, recent_changes]
    end
  end

  def oldest_candles_for_periods(instruments, periods: [15, 60], now: Time.current)
    ApplicationRecord.benchmark "RecentChanges.oldest_candles_for_periods".magenta, silence: true do
      all_candles = Candle::M1.for(instruments).today
      candles = {}
      periods.each do |duration|
        last_candle_ids = all_candles.where('time < ?', (now - duration.minutes).strftime('%H:%M')).group(:ticker).pluck('max(id)')
        candles[duration] = all_candles.where(id: last_candle_ids).index_by(&:ticker)
      end
      candles
    end
  end
end
