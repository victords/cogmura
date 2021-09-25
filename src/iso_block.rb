include MiniGL

Vector = MiniGL::Vector

class IsoBlock < Block
  def initialize(i, j, type, index = 0)
    super(i * Physics::UNIT, j * Physics::UNIT, Physics::UNIT, Physics::UNIT)
    @img = Res.imgs(type, 1, 1)[index]
    @v_offset = Graphics::SCALE * @img.height - Graphics::TILE_HEIGHT
  end

  def draw(x, y, z)
    @img.draw(x, y - @v_offset, z, Graphics::SCALE, Graphics::SCALE)
  end
end
