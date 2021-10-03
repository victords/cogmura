include MiniGL

Vector = MiniGL::Vector

class IsoBlock
  V_OFFSET = Physics::V_UNIT

  attr_reader :x, :y, :w, :h, :height, :ramps

  def initialize(col, row, height, angled = false)
    unit = Physics::UNIT

    # making the "main" block not collide, since the collision will be checked against the ramps
    @x = angled ? -10000 : col * unit
    @y = row * unit
    @w = unit
    @h = unit
    @col = col
    @row = row
    @height = height
    @z_index = col + row + (angled ? 3 : 1)
    @img = Res.imgs(angled ? :block2 : :block1, 1, 1)[0]
    
    @ramps = angled ? [
      Ramp.new(col * unit, row * unit, unit, unit, true, false),
      Ramp.new((col + 1) * unit, row * unit, unit, unit, false, false),
      Ramp.new(col * unit, (row + 1) * unit, unit, unit, true, true),
      Ramp.new((col + 1) * unit, (row + 1) * unit, unit, unit, false, true)
    ] : nil
  end
  
  def passable; false; end

  def bounds
    Rectangle.new(@x, @y, @w, @h)
  end
  
  def intersect?(obj)
    if @ramps
      @ramps.any? { |r| r.intersect?(obj) }
    else
      bounds.intersect?(obj)
    end
  end

  def draw(map)
    pos = map.get_screen_pos(@col, @row)
    pos.y += Graphics::TILE_HEIGHT / 2 if @ramps
    (1..@height).each do |i|
      @img.draw(pos.x, pos.y - i * V_OFFSET, @z_index, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
