require_relative 'iso_game_object'

class ScreenEnemy < IsoGameObject
  TYPE_MAP = [
    [:bruk, 20, -8, -4, 1, 3]
  ]

  attr_reader :type, :name
  attr_writer :on_encounter

  def initialize(type, col, row)
    id, size, img_gap_x, img_gap_y, sprite_cols, sprite_rows = TYPE_MAP[type]
    super(col, row, size, size, "char_#{id}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @type = id
    @name = id.to_s.split('_').map(&:capitalize).join(' ')
  end

  def update(man)
    if man.bounds.intersect?(bounds)
      @on_encounter.call(self)
    end
  end
end
