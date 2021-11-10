namespace :futures do
  envtask :load do
    data = JSON.parse File.read("tmp/futures.json")
    p data.pluck('exchange').uniq
  end
end

__END__

r futures:load
