require_relative '../constants'

include MiniGL

class PanelImage < MiniGL::Component
  def initialize(x, y, image, scale_x = Graphics::SCALE, scale_y = Graphics::SCALE, anchor = nil)
    super(x, y, nil, nil, nil, nil)
    @image = Res.img(image)
    @scale_x = scale_x
    @scale_y = scale_y
    @anchor = anchor
    @anchor_offset_x = x
    @anchor_offset_y = y
  end

  def draw(alpha, z_index, color)
    c = (alpha << 24) | color
    @image.draw(@x, @y, z_index, @scale_x, @scale_y, c)
  end
end
