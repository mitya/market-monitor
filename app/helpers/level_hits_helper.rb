module LevelHitsHelper
  def level_hit_color(hit)
    class_names livel_hit_kind_color(hit.kind), 'opacity-50': hit.loose?
  end

  def livel_hit_kind_color(kind)
    PriceLevelHit::PositiveKinds.include?(kind) ? 'text-green' : 'text-red'
  end

  def livel_hit_kind_button_color(kind)
    PriceLevelHit::PositiveKinds.include?(kind) ? 'btn-outline-success' : 'btn-outline-danger' if kind.present?
  end

  def ma_badge(length)
    tag.span "MA #{length}", class: "badge #{MA_BG_CLASSES[length]}" if length
  end

  def mini_ma_badge(length, **args)
    tag.span length, class: ['badge', MA_BG_CLASSES[length]], **args if length
  end

  MA_BG_CLASSES = {
    20  => 'bg-secondary',
    50  => 'bg-success',
    100 => 'bg-warning',
    200 => 'bg-danger',
  }
end
