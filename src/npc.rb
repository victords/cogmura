require_relative 'iso_block'

class Npc < IsoGameObject
  ID_MAP = [
    [:cogjian, -12, -72]
  ].freeze

  attr_reader :height, :ramps
  attr_writer :man_in_range

  def initialize(id, col, row)
    super(col, row, 20, 20, ID_MAP[id][0], Vector.new(ID_MAP[id][1], ID_MAP[id][2]))
    @height = 3
    @ramps = nil
    @range = Rectangle.new(@x - Physics::UNIT, @y - Physics::UNIT, @w + 2 * Physics::UNIT, @h + 2 * Physics::UNIT)
    @balloon = Res.img(:balloon)
  end

  def passable; false; end

  def intersect?(obj)
    bounds.intersect?(obj)
  end

  def in_range?(obj)
    @range.intersect?(obj)
  end

  def draw(map)
    super
    if @man_in_range
      pos = map.get_screen_pos((@x + @w / 2) / Physics::UNIT, (@y + @h / 2) / Physics::UNIT)
      @balloon.draw(pos.x + Graphics::TILE_WIDTH / 2 - 14, pos.y - 2 * Physics::V_UNIT + @img_gap.y, @z_index, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
