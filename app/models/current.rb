class Current
  def self.date
    Time.current.hour < 6 ? Date.yesterday : Date.today
  end
end
