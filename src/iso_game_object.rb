require_relative 'constants'

class IsoGameObject < MiniGL::GameObject
  include MiniGL

  attr_reader :z, :height, :screen_x, :screen_y, :img_size, :img_gap, :z_index, :ramps

  def initialize(col, row, layer, w, h, img, img_gap, sprite_cols, sprite_rows, height = 1)
    super((col + 0.5) * Physics::UNIT - w / 2, (row + 0.5) * Physics::UNIT - h / 2, w, h, img, img_gap, sprite_cols, sprite_rows)
    @z = (layer || 0) * Physics::V_UNIT
    @speed_z = 0
    @height = height * Physics::V_UNIT
    @z_index = calculate_z_index(col + 0.5, row + 0.5)
    @screen_x = @screen_y = -10_000
    @img_size = Vector.new(@img[0].width * Graphics::SCALE, @img[0].height * Graphics::SCALE)
  end

  def height_level
    (@z / Physics::V_UNIT).floor
  end

  def intersect?(obj)
    bounds.intersect?(obj)
  end

  def vert_intersect?(obj)
    obj.z + obj.height > @z && @z + @height > obj.z
  end

  def plane_distance(obj)
    Math.sqrt((@x - obj.x)**2 + (@y - obj.y)**2)
  end

  def move_to(col, row, layer)
    @x = (col + 0.5) * Physics::UNIT - @w / 2
    @y = (row + 0.5) * Physics::UNIT - @h / 2
    @z = layer * Physics::V_UNIT
    @speed = Vector.new
    @speed_z = 0
  end

  def draw(map, z_index = nil, alpha = 255)
    i = (@x + @w / 2).to_f / Physics::UNIT
    j = (@y + @h / 2).to_f / Physics::UNIT
    phys_x = @x; phys_y = @y
    @x = (map.size.y + i - j) * map.tile_size.x / 2 - @w / 2
    @y = (i + j) * map.tile_size.y / 2 - @z - @h + Graphics::V_OFFSET
    @z_index = z_index || calculate_z_index(i, j)
    @screen_x = @x - map.cam.x + @img_gap.x
    @screen_y = @y - map.cam.y + @img_gap.y
    super(map, Graphics::SCALE, Graphics::SCALE, alpha, 0xffffff, nil, @flip ? :horiz : nil, @z_index)
    @x = phys_x; @y = phys_y
  end

  private

  def calculate_z_index(i, j)
    (100 * (i.floor + j.floor) + 10 * height_level + 5 * (i - i.floor + j - j.floor)).floor
  end
end
