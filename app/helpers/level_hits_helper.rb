module LevelHitsHelper
  def level_hit_color(hit)
    class_names HitColors[hit.kind], 'opacity-50': hit.loose?
  end

  HitColors = {
    fall:          'text-red',
    rise:          'text-green',
    'retest-down': 'text-green',
    'retest-up':   'text-red',
  }.stringify_keys
end
