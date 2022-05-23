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

class Object
  def __unmemoize(method)
    instance_variable_set "@#{method}", nil
  end
end

class Class
  def memoize(method)
    alias_method "#{method}_without_memoization", method
    # define_method method do
    #   result = instance_variable_get "@_#{method}"
    #   return result unless result == nil
    #
    #   result = send("#{method}_without_memoization")
    #   instance_variable_set "@_#{method}", result
    # end

    module_eval <<-EOS, __FILE__, __LINE__ + 1
      def #{method}
        @_#{method} ||= #{method}_without_memoization
      end
    EOS
  end

  def thread_memoize(method)
    alias_method "#{method}_without_memoization", method

    module_eval <<-EOS, __FILE__, __LINE__ + 1
      def #{method}
        if object_id = thread_object_id
          full_object_id = "#{name}" +  object_id.to_s + "#{method}"
          Thread.current[full_object_id] ||= #{method}_without_memoization
        else
          #{method}_without_memoization
        end
      end
    EOS
  end
end
