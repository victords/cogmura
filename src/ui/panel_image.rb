require_relative '../constants'

include MiniGL

class PanelImage < MiniGL::Component
  def initialize(x, y, image, scale_x = 1, scale_y = 1, anchor = nil)
    super(x, y, nil, nil, nil, nil)
    @image = Res.img(image)
    @scale_x = scale_x * Graphics::SCALE
    @scale_y = scale_y * Graphics::SCALE
    @w = @scale_x * @image.width
    @h = @scale_y * @image.height
    @anchor = anchor
    @anchor_offset_x = x
    @anchor_offset_y = y
  end

  def draw(alpha, z_index, color)
    c = (alpha << 24) | color
    @image.draw(@x, @y, z_index, @scale_x, @scale_y, c)
  end
end
