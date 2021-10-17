require_relative 'iso_game_object'

include MiniGL

class ScreenItem < IsoGameObject
  TYPE_MAP = [
    [:pakia, -2, -4, 1, 1]
  ].freeze

  attr_reader :type, :destroyed
  attr_writer :on_picked_up

  def initialize(type, col, row)
    img, img_gap_x, img_gap_y, sprite_cols, sprite_rows = TYPE_MAP[type]
    super(col, row, 16, 16, "item_#{img}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @type = type
  end

  def update(man)
    return unless man.bounds.intersect?(bounds)

    @on_picked_up.call(self)
    @destroyed = true
  end
end
