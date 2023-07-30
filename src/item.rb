require_relative 'iso_game_object'

include MiniGL

class Item < IsoGameObject
  MAP = [
    [:pakia, -12, -28, 1, 1],
    [:grayMush, -16, -24, 1, 1],
    [:lifeMush, -16, -24, 1, 1],
  ].freeze

  attr_reader :key, :destroyed
  attr_writer :on_picked_up

  def initialize(id, col, row, layer, on_picked_up)
    key, img_gap_x, img_gap_y, sprite_cols, sprite_rows = MAP[id]
    super(col, row, layer, 16, 16, "item_#{key}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @key = key
    @on_picked_up = on_picked_up
  end

  def update(man)
    return unless man.bounds.intersect?(bounds) && man.vert_intersect?(self)

    @on_picked_up.call(@key)
    @destroyed = true
  end
end
