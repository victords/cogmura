require_relative 'iso_game_object'
require_relative 'constants'

class Door < IsoGameObject
  attr_reader :dest_scr, :dest_entr
  attr_writer :on_open

  def initialize(dest_scr, dest_entr, i, j, z)
    super(i, j, Physics::UNIT, Physics::UNIT, :door1, Vector.new(-4, -76), 5, 1)
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    @z = z
  end

  def update(man)
    if @opening
      animate_once([1, 2, 3, 4], 7)
    elsif man.bounds.intersect?(bounds) && KB.key_pressed?(Gosu::KB_Z)
      @on_open.call(self)
      @opening = true
    end
  end
end
