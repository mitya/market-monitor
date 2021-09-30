require 'csv'

class ParseVtbMarginFactors
  include StaticService

  def run
    CSV.read("db/data/vtb-margin-factors.csv", headers: true, col_sep: ';', quote_char: nil).each do |row|
      title, type, ticker_spb, k_long, k_short, on_iis, can_short, list_1, list_2 = row.fields
      next unless type.in? %w[акции АО АП]
      ticker = ticker_spb.gsub('_SPB', '')
      instrument = Instrument[ticker]
      next puts "Missing #{ticker}".red if instrument == nil

      instrument.info!.update! extra: instrument.info!.extra.to_h.merge({
        vtb_long_risk: k_long.presence && k_long.to_f * 100, vtb_short_risk: k_short.presence && k_short.to_f * 100,
        vtb_can_short: can_short == 'да', vtb_on_iis: on_iis == 'да',
        vtb_list_1: list_1 == 'да', vtb_list_2: list_2 == 'да',
      }.stringify_keys).compact_blank
    end
  end

  delegate :logger, to: :Rails
end

__END__
ParseVtbMarginFactors.run
