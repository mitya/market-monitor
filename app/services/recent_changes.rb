class RecentChanges
  include StaticService

  def prepare(instruments, intervals: [60], now: Time.current)
    recent_gains = {}
    recent_losses = {}
    recent_changes = {}

    intervals.each do |interval|
      recent_candles = Candle::M1.for(instruments).today.where(time: (now - interval.minutes).to_hhmm .. now.to_hhmm).order(:time).group_by(&:instrument)
      recent_candles.reject! { |inst, candles| candles.size < 5 }
      recent_gains[interval]  = recent_candles.map { |inst, candles| [inst.ticker, inst.gain_since(candles.minimum(:low),  :last)] }.to_h
      recent_losses[interval] = recent_candles.map { |inst, candles| [inst.ticker, inst.gain_since(candles.maximum(:high), :last)] }.to_h
      recent_changes[interval] = recent_candles.map do |inst, _|
        gain = recent_gains[interval][inst.ticker]
        loss = recent_losses[interval][inst.ticker]
        [inst.ticker, gain.abs > loss.abs ? gain : loss]
      end.to_h
    end

    [recent_gains, recent_losses, recent_changes]
  end
end
