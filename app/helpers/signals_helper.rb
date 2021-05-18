module SignalsHelper
  def signal_source(source)
    SOURCES[source] || source
  end

  SOURCES = {
    'Kogan-A' => 'Коган Агрессивный',
    'Kogan-R' => 'Коган Россия',
    'Kogan-2' => 'Коган 2-й Эшелон',
    'Kogan-O' => 'Коган Оптимальный',
  }
end
