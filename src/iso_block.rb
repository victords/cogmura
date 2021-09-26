include MiniGL

Vector = MiniGL::Vector

class IsoBlock < Block
  def initialize(map, i, j, type, index = 0)
    super(i * Physics::UNIT, j * Physics::UNIT, Physics::UNIT, Physics::UNIT)
    @col = i
    @row = j
    @z_index = i + j + 1
    @img = Res.imgs(type, 1, 1)[index]
    @v_offset = Graphics::SCALE * @img.height - Graphics::TILE_HEIGHT
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    @img.draw(pos.x, pos.y - @v_offset, @z_index, Graphics::SCALE, Graphics::SCALE)
  end
end
