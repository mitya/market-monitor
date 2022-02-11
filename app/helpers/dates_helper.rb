module DatesHelper
  def format_date(date)
    l date, format: :long if date
  end

  def days_ago(date, suffix = ' days ago')
    if date
      days = (Current.date - date).to_i
      "#{days}#{suffix}"
    end
  end

  def days_ago_number(date)
    (Current.date - date).to_i if date
  end

  def seconds_ago(time)
    (Time.current - time).round if time
  end

  def date_in_words(date)
    return unless date
    date = date.to_date
    case
      when date.to_date == Current.today then 'today'
      when date.to_date == Current.yesterday then 'yesterday'
      when date >= Current.d7_ago then sessions_ago(date)
      else days_ago(date)
    end
  end

  def date_as_wday(date)
    return if !date
    # return 'Yesterday' if date == Current.yesterday
    # return 'Today' if date == Current.today
    "#{l date, format: :wday_name}, #{date.day.ordinalize}"
  end

  def date_as_mday(date)
    l date, format: :mday if date
  end

  def format_as_minutes_since(since, minutes)
    minutes = since + minutes
    hour, minute = minutes.divmod(60)
    "#{hour.to_s.rjust(2, '0')}:#{minute.to_s.rjust(2, '0')}"
  end

  def format_date_as_text_with_days(date)
    "On #{format_date date} | #{days_ago date}"
  end    
  
  def days_old_badge(date)
    return if date.blank?
    days_ago = (Current.date - date).to_i
    color = days_ago > 350 ? 'bg-danger' : days_ago > 95 ? 'bg-dark' : days_ago > 35 ? 'bg-dark' : 'bg-secondary'
    # text = Current.date == date ? 'today' : "#{days_ago} d"
    # text = Current.date == date ? 'today' : distance_of_time_in_words(date, Current.date, scope: 'datetime.distance_in_words.short')
    text = date.year == Current.date.year ? l(date, format: :month) : l(date, format: :month_year)
    tag.span text, class: "badge #{color}", title: date
  end  
end