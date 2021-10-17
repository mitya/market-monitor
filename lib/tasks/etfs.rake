namespace :spdr do
  envtask :load do
    etfs = %w[XAR XBI XES XHB XHE XHS XLB XLC XLE XLF XLI XLK XLP XLU XLV XLY XME XOP XPH XRT XSD XSW XTN]
    etfs.each do |etf|
      # url = "https://www.ssga.com/us/en/intermediary/etfs/library-content/products/fund-data/etfs/us/holdings-daily-us-en-#{etf.downcase}.xlsx"
      url = "https://www.ssga.com/library-content/products/fund-data/etfs/us/holdings-daily-us-en-#{etf.downcase}.xlsx"
      cmd = "curl -s #{url} > tmp/spdr-#{etf.downcase}.xlsx"
      system cmd
    end
  end

  envtask :convert do
    Pathname.glob("tmp/spdr-*.xlsx") do |path|
      cmd = "ssconvert #{path} tmp/#{path.basename('.xlsx')}.csv"
      puts cmd
    end
  end

  envtask :create do
    Pathname.glob("tmp/spdr-*.xlsx") do |path|
      etf = path.basename('.xlsx')
      system "touch db/instrument-sets/#{etf}.txt"
    end
  end
end




__END__

r spdr:load
r spdr:convert
r spdr:create
