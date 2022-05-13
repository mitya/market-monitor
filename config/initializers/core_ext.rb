class String
  def purple
    magenta
  end
end

class Time
  def self.ms(milliseconds)
    Time.at milliseconds / 1000 if milliseconds.is_a?(Numeric)
  end

  def to_hhmm
    to_fs :time
  end

  def self.plain_time(hours, minutes = 0, seconds = 0)
    Time.utc(2000, 1, 1, hours, minutes, seconds)
  end
end

class Date
  def self.ms(milliseconds)
    Time.ms(milliseconds)&.to_date
  end

  def ms
    to_time.to_i * 1000
  end

  def self.to_date(date)
    self === date ? date : parse(date)
  end
end

module Math
  def self.in_delta?(x, y, accuracy)
    (x - y).abs <= x * accuracy
  end
end

class Array
  def average
    return nil if count == 0
    sum / count
  end

  def to_inclusive_range
    first .. last
  end
end

class Integer
  Max31 = 2**31 - 1
end
