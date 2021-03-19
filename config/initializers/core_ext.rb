class String
  def purple
    magenta
  end
end

class Time
  def self.ms(milliseconds)
    Time.at milliseconds / 1000 if milliseconds.is_a?(Numeric)
  end
end

class Date
  def self.ms(milliseconds)
    Time.ms(milliseconds)&.to_date
  end
end
