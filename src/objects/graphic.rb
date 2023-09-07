require_relative '../constants'

class Graphic
  TYPE_MAP = [
    [:bush1, -64, -72]
  ]

  attr_reader :col, :row, :args

  def initialize(col, row, layer, args)
    @col = col
    @row = row
    @layer = layer || 0
    @args = args
    type = args[0].to_i
    img, img_gap_x, img_gap_y = TYPE_MAP[type]
    @z = @layer * Physics::V_UNIT
    @img = Res.img("obj_#{img}")
    @img_gap = Vector.new(img_gap_x, img_gap_y)
    @z_index = 100 * (col + row) + 10 * @layer + 5
  end

  def collide?
    false
  end

  def move_to(col, row, layer)
    @col = col
    @row = row
    @layer = layer
    @z = layer * Physics::V_UNIT
    @z_index = 100 * (col + row) + 10 * layer + 5
    @pos = nil
  end

  def height_level
    @layer
  end

  def update(_, _); end

  def draw(map, z_index = nil, alpha = 255)
    if @pos.nil?
      @pos = map.get_screen_pos(@col, @row)
    end

    color = (alpha << 24) | 0xffffff
    @img.draw(
      @pos.x + 0.5 * Graphics::TILE_WIDTH + @img_gap.x,
      @pos.y + 0.5 * Graphics::TILE_HEIGHT + @img_gap.y - @z,
      z_index || @z_index,
      1, 1, color
    )
  end
end
