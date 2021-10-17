require_relative 'constants'

include MiniGL

class IsoGameObject < GameObject
  attr_reader :z, :screen_x, :screen_y, :z_index

  def initialize(i, j, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil)
    super((i + 0.5) * Physics::UNIT - w / 2, (j + 0.5) * Physics::UNIT - h / 2, w, h, img, img_gap, sprite_cols, sprite_rows)
    @screen_x = @screen_y = -10000
    @z = 0
    @z_index = i + j + 1
  end

  def height_level
    (@z / Physics::V_UNIT).floor
  end

  def draw(map, flip = nil, z_index = nil)
    i = (@x + @w / 2).to_f / Physics::UNIT
    j = (@y + @h / 2).to_f / Physics::UNIT
    phys_x = @x; phys_y = @y
    @x = (map.size.y + i - j) * map.tile_size.x / 2 - @w / 2
    @y = (i + j) * map.tile_size.y / 2 - @z - @h
    @z_index = z_index || (i.floor + j.floor + 1)
    @screen_x = @x - map.cam.x
    @screen_y = @y - map.cam.y
    super(map, Graphics::SCALE, Graphics::SCALE, 255, 0xffffff, nil, flip, @z_index)
    @x = phys_x; @y = phys_y
  end
end
