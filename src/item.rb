require_relative 'iso_game_object'

include MiniGL

class Item < IsoGameObject
  TYPE_MAP = [
    [:pakia, -12, -28, 1, 1],
    [:lifeMush, -16, -24, 1, 1],
  ].freeze

  attr_reader :type, :destroyed
  attr_writer :on_picked_up

  def initialize(type, col, row, layer, on_picked_up)
    id, img_gap_x, img_gap_y, sprite_cols, sprite_rows = TYPE_MAP[type]
    super(col, row, layer, 16, 16, "item_#{id}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @type = id
    @on_picked_up = on_picked_up
  end

  def update(man)
    return unless man.bounds.intersect?(bounds) && man.vert_intersect?(self)

    @on_picked_up.call(@type)
    @destroyed = true
  end
end
