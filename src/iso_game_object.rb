require_relative 'constants'

include MiniGL

class IsoGameObject < GameObject
  def initialize(i, j, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil)
    super(i * Physics::UNIT, j * Physics::UNIT, w, h, img, img_gap, sprite_cols, sprite_rows)
    @z = 0
  end

  def x_c
    (@x + @w / 2).to_f
  end

  def y_c
    (@y + @h / 2).to_f
  end

  def draw(map, flip = nil)
    i = x_c / Physics::UNIT
    j = y_c / Physics::UNIT
    phys_x = @x; phys_y = @y
    @x = (map.size.y + i - j) * map.tile_size.x / 2 - @w / 2
    @y = (i + j) * map.tile_size.y / 2 - @z
    super(map, Graphics::SCALE, Graphics::SCALE, 255, 0xffffff, nil, flip, i.floor + j.floor + 1)
    @x = phys_x; @y = phys_y
  end
end
