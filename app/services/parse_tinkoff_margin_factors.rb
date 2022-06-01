# https://www.tinkoff.ru/invest/margin/equities/
class ParseTinkoffMarginFactors
  include StaticService

  def run(real = false)
    doc = Nokogiri::HTML open("db/data/tinkoff-margin-factors.html"), nil, "UTF-8"

    doc.css("tr[data-qa-type='uikit/table.tableRow']").each do |node|
      title = node.css('.LiquidPapersPure__subtitle_z6_Py').first&.content
      next if not title
      isin = node.css('td:nth-child(2)').first.content
      can_short = node.css('td:nth-child(3)').first.content == 'Доступен'
      values = node.css('td:nth-child(4)').first.content
      ticker = title.split(',').first
      long_k, short_k = values.split('/').map { |v| v.squish.to_f }

      printf "%-14s %14s %8.2f %8.2f %s\n", ticker, isin, long_k.to_f, short_k.to_f, can_short ? 'SHORT' : nil
      next

      instrument = Instrument[ticker]
      next puts "Missing #{ticker}".red if instrument == nil
      instrument.info!.update! extra: instrument.info!.extra.to_h.merge({
        tinkoff_long_risk: long_k,
        tinkoff_short_risk: short_k,
        tinkoff_can_short: can_short
      }.stringify_keys).compact_blank
    end

    nil
  end
end


__END__

ParseTinkoffMarginFactors.run
