require_relative '../constants'

class Graphic
  TYPE_MAP = [
    [:bush1, 0, -16]
  ]

  def initialize(type, col, row, layer)
    layer ||= 0
    img, img_gap_x, img_gap_y = TYPE_MAP[type]
    @col = col
    @row = row
    @z = layer * Physics::V_UNIT
    @img = Res.img("obj_#{img}")
    @img_gap = Vector.new(img_gap_x, img_gap_y)
    @z_index = col + row + (layer / 3) + 2
  end

  def collide?
    false
  end

  def update(_); end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    @img.draw(pos.x + @img_gap.x, pos.y + @img_gap.y - @z + Graphics::V_OFFSET, @z_index, Graphics::SCALE, Graphics::SCALE)
  end
end
