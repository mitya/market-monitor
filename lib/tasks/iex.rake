require 'csv'
require 'open-uri'

namespace :iex do
  task :logos => :environment do
    Instrument.usd.each do |inst|
      response = IexConnector.logo(inst.ticker)
      url = response['url'].presence
      puts "Icon for #{inst.ticker}: #{url}"
      open('tmp/icons.csv', 'a') { |f| f.print CSV.generate_line([inst.ticker, url]) }
      sleep 0.5
    end
  end

  task 'logos:download' => :environment do
    Instrument.usd.abc.each do |inst|
      next if File.exist? "tmp/logos/#{inst.ticker}.png"

      puts "Load #{inst.ticker}"
      URI.open("https://storage.googleapis.com/iexcloud-hl37opg/api/logos/#{inst.ticker}.png", 'rb') do |remote_file|
        open("tmp/logos/#{inst.ticker}.png", 'wb') { |file| file << remote_file.read }
      end

      sleep 0.5
    rescue OpenURI::HTTPError
      puts "Mising #{inst.ticker}"
      sleep 0.5
    end
  end

  task :stats => :environment do
    InstrumentInfo.refresh
  end
end


__END__
rake iex:logos
rake iex:logos:download

rake iex:stats
