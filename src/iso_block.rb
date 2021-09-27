include MiniGL

Vector = MiniGL::Vector

class IsoBlock < Block
  V_OFFSET = Physics::V_UNIT

  attr_reader :height

  def initialize(i, j, height, index = 0)
    super(i * Physics::UNIT, j * Physics::UNIT, Physics::UNIT, Physics::UNIT)
    @col = i
    @row = j
    @z_index = i + j + 1
    @img = Res.imgs(:block1, 1, 1)[index]
    @height = height
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    (1..@height).each do |i|
      @img.draw(pos.x, pos.y - i * V_OFFSET, @z_index, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
