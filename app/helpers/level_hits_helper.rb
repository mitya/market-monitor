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
end
