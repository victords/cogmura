require_relative '../constants'

include MiniGL

class PanelImage < MiniGL::Component
  def initialize(x, y, image, scale_x = 1, scale_y = 1, anchor = nil, sprite_cols = 1, sprite_rows = 1, img_index = 0)
    super(x, y, nil, nil, nil, nil)
    @image = Res.imgs(image, sprite_cols, sprite_rows)
    @img_index = img_index
    @scale_x = scale_x
    @scale_y = scale_y
    @w = @scale_x * @image[0].width
    @h = @scale_y * @image[0].height
    @anchor = anchor
    @anchor_offset_x = x
    @anchor_offset_y = y
  end

  def image=(id, sprite_cols = 1, sprite_rows = 1)
    @image = Res.imgs(id, sprite_cols, sprite_rows)
  end

  def draw(alpha, z_index, color)
    c = (alpha << 24) | color
    @image[@img_index].draw(@x, @y, z_index, @scale_x, @scale_y, c)
  end
end
