require_relative '../constants'

class Graphic
  TYPE_MAP = [
    [:bush1, -64, -72]
  ]

  def initialize(map, type, col, row, layer)
    layer ||= 0
    img, img_gap_x, img_gap_y = TYPE_MAP[type]
    @pos = map.get_screen_pos(col, row)
    @z = layer * Physics::V_UNIT
    @img = Res.img("obj_#{img}")
    @img_gap = Vector.new(img_gap_x, img_gap_y)
    @z_index = 100 * (col + row) + 10 * layer + 5
  end

  def collide?
    false
  end

  def update(_); end

  def draw(map)
    @img.draw(
      @pos.x + 0.5 * Graphics::TILE_WIDTH + @img_gap.x,
      @pos.y + 0.5 * Graphics::TILE_HEIGHT + @img_gap.y - @z + Graphics::V_OFFSET,
      @z_index, Graphics::SCALE, Graphics::SCALE
    )
  end

  def drawn?; false; end
end
