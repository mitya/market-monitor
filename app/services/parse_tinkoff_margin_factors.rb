class ParseTinkoffMarginFactors
  include StaticService

  def run
    doc = Nokogiri::HTML open("db/data/tinkoff-margin-factors.html"), nil, "UTF-8"

    doc.css('.Table__table_14Vfq tbody tr').each do |node|
      title = node.css('.LiquidPapersPure__subtitle_ggFbH').first.content
      isin = node.css('.LiquidPapersPure__isin_1N24p').first.content
      can_short = node.css('td:nth-child(3) .Table__linkCell_38tXR').first.content == 'Доступен'
      values = node.css('td:nth-child(4) .Table__linkCell_38tXR').first.content
      ticker = title.split(',').first
      long_k, short_k = values.split('/').map { |v| v.squish.to_f }
      # puts "#{ticker} #{long_k} #{short_k}"

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
