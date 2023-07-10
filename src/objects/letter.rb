require_relative '../constants'

class Letter
  def initialize(map, col, row, layer)
    layer ||= 0
    @pos = map.get_screen_pos(col, row)
    @z = layer * Physics::V_UNIT
    @z_index = 100 * (col + row + 1) + 10 * layer + 5
    @img = Res.img(:obj_letter)
  end

  def collide?
    false
  end

  def update(_); end

  def draw(map)
    @img.draw(
      @pos.x + 0.5 * (Graphics::TILE_WIDTH - @img.width),
      @pos.y + 0.5 * (Graphics::TILE_HEIGHT - @img.height) - @z + Graphics::V_OFFSET,
      @z_index, Graphics::SCALE, Graphics::SCALE
    )
  end
end
