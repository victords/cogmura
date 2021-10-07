require_relative 'constants'

class Graphic
  TYPE_MAP = [
    [:bush1, 0, -8]
  ]

  def initialize(type, col, row)
    img, img_gap_x, img_gap_y = TYPE_MAP[type]
    @col = col
    @row = row
    @img = Res.img(img)
    @img_gap = Vector.new(img_gap_x, img_gap_y)
    @z_index = col + row + 2
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    @img.draw(pos.x + @img_gap.x, pos.y + @img_gap.y, @z_index, Graphics::SCALE, Graphics::SCALE)
  end
end