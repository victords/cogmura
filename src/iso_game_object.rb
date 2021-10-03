require_relative 'constants'

include MiniGL

class IsoGameObject < GameObject
  def initialize(i, j, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil)
    super(i * Physics::UNIT, j * Physics::UNIT, w, h, img, img_gap, sprite_cols, sprite_rows)
    @z = 0
  end

  def height_level
    (@z / Physics::V_UNIT).floor
  end

  def draw(map, flip = nil, z_index = nil)
    i = (@x + @w / 2).to_f / Physics::UNIT
    j = (@y + @h / 2).to_f / Physics::UNIT
    phys_x = @x; phys_y = @y
    @x = (map.size.y + i - j) * map.tile_size.x / 2 - @w / 2
    @y = (i + j) * map.tile_size.y / 2 - @z
    z_index ||= i.floor + j.floor + 1
    super(map, Graphics::SCALE, Graphics::SCALE, 255, 0xffffff, nil, flip, z_index)
    @x = phys_x; @y = phys_y
  end
end
