require_relative '../constants'

include MiniGL

class PanelImage < MiniGL::Component
  def initialize(x, y, image, anchor = nil)
    super(x, y, nil, nil, nil, nil)
    @image = Res.img(image)
    @anchor = anchor
    @anchor_offset_x = x
    @anchor_offset_y = y
  end

  def draw(alpha, z_index, color)
    c = (alpha << 24) | color
    @image.draw(@x, @y, z_index, Graphics::SCALE, Graphics::SCALE, c)
  end
end
