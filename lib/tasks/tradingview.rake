namespace :tv do
  task :expirations => :environment do
    witchings = %w[
      2020-03-20
      2020-06-19
      2020-09-18
      2020-12-18
      2021-03-19
      2021-06-18
      2021-09-17
      2021-12-17
    ].map(&:to_date)

    expirations = %w[
      2020-01-17
      2020-02-21
      2020-04-17
      2020-05-15
      2020-07-17
      2020-08-21
      2020-10-16
      2020-11-20
      2021-01-15
      2021-02-19
      2021-04-16
      2021-05-21
      2021-07-16
      2021-08-20
      2021-10-15
      2021-11-19
    ].map(&:to_date)

    result = expirations.map do |date|
      "  (y == #{date.year} and m == #{date.month.to_s.rjust(2)} and d == #{date.day})"
    end.join(" or\n")

    result << "\n\n"
    result << witchings.map do |date|
      "  (y == #{date.year} and m == #{date.month.to_s.rjust(2)} and d == #{date.day})"
    end.join(" or\n")

    puts result
  end
end

__END__
r tv:expirations
