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

  def signal_score_badge(signal)
    return unless signal.source == 'SA'
    text = PublicSignal::SA_RATINGS_INV[signal.score]
    seeking_alpha_badge signal.score, style: 'width: auto;' do
      tag.span text, class: 'changebox-green'
    end
  end

  def seeking_alpha_badge(score, text = nil, **options, &block)
    tag.span text, class: "badge sa-badge sa-badge-#{score}", **options, &block
  end

  def seeking_alpha_price_badge(inst, score, price, format: 'relative')
    return unless score
    link_to seeking_alpha_url(inst), target: '_blank' do
      seeking_alpha_badge score do
        if price
          relative_price inst.base_price, price.to_d, unit: inst.currency, format: format
        else
          '—'
        end
      end
    end
  end

  def signal_source_options
    PublicSignal.distinct.pluck(:source).sort + ['Non-SA']
  end

  def signal_short_name(kind)
    SIGNAL_SHORT_NAME[kind] || kind
  end

  SIGNAL_SHORT_NAME = {
    volume_spike: 'volume'
  }.transform_keys { _1.to_s.dasherize }
end
