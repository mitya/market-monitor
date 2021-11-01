namespace :list do
  envtask :clear do
    puts ENV['tickers'].split(',').map{ |tk| tk.split(':').last }.sort.join("\n")
  end

  envtask :import do
    list = ENV['list']
    file = Pathname("db/instrument-sets/#{list}.txt")
    text = file.read
    text = text.gsub(',', "\n")
    tickers = text.each_line.map { |line| line.to_s.split(':').last.upcase.chomp.presence }.uniq.compact
    file.write(tickers.join("\n"))
  end
end
