class PantiniNewsParser
  include StaticService

  def connect
    puts "Sync news from Pantini"
    command = "coffee bin/telegram.coffee messages NEWS"
    data = `#{command}`
    data = JSON.parse data, object_class: OpenStruct
    data.each { |item| parse item }
  end

  def test
    data = JSON.parse File.read("db/data/pantini-news-sample.json"), object_class: OpenStruct
    data.each { |item| parse item }
  end

  def parse(item)
    tickers_line, datetime_line, title_line, *body_lines = item.text.lines
    tickers = tickers_line.scan(/\$(\w+)/).flatten
    ticker = tickers.first
    source = item.url.to_s.include?('seekingalpha') ? 'SeekingAlpha' : 'Pantini'

    News.find_or_create_by(external_id: item.id) do |news|
      puts "News #{Time.at(item.date).strftime('%H:%M:%S')}: [#{ticker}] #{title_line}"
      news.assign_attributes datetime: Time.at(item.date),
        title: title_line,
        body: body_lines.join("\n").squish,
        source: source,
        url: item.url,
        ticker: ticker,
        tickers: tickers
    end
  end
end

__END__
PantiniArbitrageParser.connect
PantiniArbitrageParser.test
