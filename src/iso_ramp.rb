include MiniGL

class IsoRamp < Ramp
  def initialize(col, row, left, inverted)
    super(col * Physics::UNIT, row * Physics::UNIT, Physics::UNIT, Physics::UNIT, left, inverted)
    @col = col
    @row = row
    index = left ? (inverted ? 2 : 0) : (inverted ? 1 : 3)
    @img = Res.imgs(:slopes, 1, 4)[index]
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    @img.draw(pos.x, pos.y, @col + @row + 1, Graphics::SCALE, Graphics::SCALE)
  end
end
