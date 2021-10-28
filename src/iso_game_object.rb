require_relative 'constants'

include MiniGL

class IsoGameObject < GameObject
  attr_reader :z, :height, :screen_x, :screen_y, :z_index

  def initialize(col, row, layer, w, h, img, img_gap, sprite_cols, sprite_rows, height = 1)
    super((col + 0.5) * Physics::UNIT - w / 2, (row + 0.5) * Physics::UNIT - h / 2, w, h, img, img_gap, sprite_cols, sprite_rows)
    @z = layer * Physics::V_UNIT
    @height = height * Physics::V_UNIT
    @z_index = col + row + (layer / 3) + 1
    @screen_x = @screen_y = -10000
  end

  def height_level
    (@z / Physics::V_UNIT).floor
  end

  def vert_intersect?(obj)
    obj.z + obj.height > @z && @z + @height > obj.z
  end

  def plane_distance(obj)
    Math.sqrt((@x - obj.x) ** 2 + (@y - obj.y) ** 2)
  end

  def draw(map, z_index = nil)
    i = (@x + @w / 2).to_f / Physics::UNIT
    j = (@y + @h / 2).to_f / Physics::UNIT
    phys_x = @x; phys_y = @y
    @x = (map.size.y + i - j) * map.tile_size.x / 2 - @w / 2
    @y = (i + j) * map.tile_size.y / 2 - @z - @h
    @z_index = z_index || (i.floor + j.floor + (height_level / 3) + 1)
    @screen_x = @x - map.cam.x
    @screen_y = @y - map.cam.y
    super(map, Graphics::SCALE, Graphics::SCALE, 255, 0xffffff, nil, @flip ? :horiz : nil, @z_index)
    @x = phys_x; @y = phys_y
  end
end
