include MiniGL

Vector = MiniGL::Vector

class IsoBlock
  V_OFFSET = Physics::V_UNIT

  attr_reader :x, :y, :w, :h, :height, :ramps, :z_index

  def initialize(type, col, row, height, angled)
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
    @img = Res.img("block#{type}#{angled ? 'a' : ''}", 1, 1) if type
    
    @ramps =
      if angled
        [
          Ramp.new(col * unit, row * unit, unit, unit, true, false),
          Ramp.new((col + 1) * unit, row * unit, unit, unit, false, false),
          Ramp.new(col * unit, (row + 1) * unit, unit, unit, true, true),
          Ramp.new((col + 1) * unit, (row + 1) * unit, unit, unit, false, true)
        ]
      else
        nil
      end
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

  def draw(map, man)
    pos = map.get_screen_pos(@col, @row)
    pos.y += Graphics::TILE_HEIGHT / 2 if @ramps
    color =
      if man.screen_x + man.w > pos.x &&
         man.screen_x < pos.x + Graphics::TILE_WIDTH &&
         man.screen_y + man.h - 12 > pos.y - @height * V_OFFSET &&
         man.z_index < @z_index && man.height_level < @height
        0x80ffffff
      else
        0xffffffff
      end
    (1..@height).each do |i|
      @img.draw(pos.x, pos.y - i * V_OFFSET, @z_index, Graphics::SCALE, Graphics::SCALE, color)
    end
  end
end
