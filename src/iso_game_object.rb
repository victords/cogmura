require_relative 'constants'

include MiniGL

Vector = MiniGL::Vector

class IsoGameObject
  include Movement

  def initialize(i, j, w, h)
    @x = i * Physics::UNIT
    @y = j * Physics::UNIT
    @z = 0
    @w = w
    @h = h
    @mass = 1
    @speed = Vector.new
    @max_speed = Vector.new(15, 15)
    @stored_forces = Vector.new
  end

  def x_c
    (@x + @w / 2).to_f
  end

  def y_c
    (@y + @h / 2).to_f
  end

  def draw(map)
    i = x_c / Physics::UNIT
    j = y_c / Physics::UNIT
    map_pos = Vector.new((map.size.y + i - j) * map.tile_size.x / 2, (i + j) * map.tile_size.y / 2)
    pos = map_pos - Vector.new(map.cam.x + 10, map.cam.y + 20)
    G.window.draw_quad(pos.x, pos.y - @z, 0xff993399,
                       pos.x + 20, pos.y - @z, 0xff993399,
                       pos.x, pos.y + 20 - @z, 0xff993399,
                       pos.x + 20, pos.y + 20 - @z, 0xff993399, i.floor + j.floor + 1)
  end
end
