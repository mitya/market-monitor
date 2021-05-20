require 'csv'

class Vtb
  include StaticService

  def parse_marginal_list
    CSV.read("db/data/vtb-marginal.csv", headers: true, col_sep: ';', quote_char: nil).each do |row|
      title, type, ticker_spb, k_long, k_short, on_iis, can_short, list_1, list_2 = row.fields
      next unless type.in? %w[акции АО АП]
      ticker = ticker_spb.gsub('_SPB', '')
      instrument = Instrument[ticker]
      next puts "Missing #{ticker}".red if instrument == nil
      instrument.info!.update! extra: {
        vtb_long_risk: k_long, vtb_short_risk: k_short,
        vtb_can_short: can_short == 'да', vtb_on_iis: on_iis == 'да',
        vtb_list_1: list_1 == 'да', vtb_list_2: list_2 == 'да',
      }.compact
    end
  end

  delegate :logger, to: :Rails
end

__END__
Vtb.parse_marginal_list
