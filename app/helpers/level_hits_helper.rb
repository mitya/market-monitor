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
    badge_class = length == 50 ? 'bg-success' : 'bg-danger'
    tag.span "MA #{length}", class: "badge #{badge_class}"    
  end
end
