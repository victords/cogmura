require_relative 'constants'

include MiniGL

Vector = MiniGL::Vector

class IsoGameObject
  include Movement

  SPEED = 5
  SPEED_D = 3.535

  def initialize(x, y, w, h)
    @x = x
    @y = y
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

  def update(obstacles, map)
    up = KB.key_down?(Gosu::KB_UP)
    rt = KB.key_down?(Gosu::KB_RIGHT)
    dn = KB.key_down?(Gosu::KB_DOWN)
    lf = KB.key_down?(Gosu::KB_LEFT)
    speed =
      if up && !rt && !dn && !lf
        Vector.new(-SPEED_D, -SPEED_D)
      elsif rt && !up && !dn && !lf
        Vector.new(SPEED_D, -SPEED_D)
      elsif dn && !up && !rt && !lf
        Vector.new(SPEED_D, SPEED_D)
      elsif lf && !up && !rt && !dn
        Vector.new(-SPEED_D, SPEED_D)
      elsif up && rt && !dn && !lf
        Vector.new(0, -SPEED)
      elsif rt && dn && !up && !lf
        Vector.new(SPEED, 0)
      elsif dn && lf && !up && !rt
        Vector.new(0, SPEED)
      elsif lf && up && !rt && !dn
        Vector.new(-SPEED, 0)
      else
        Vector.new(0, 0)
      end
    move(speed, obstacles, [], true)

    i = x_c / Physics::UNIT
    j = y_c / Physics::UNIT
    @map_pos = Vector.new((map.size.y + i - j) * map.tile_size.x / 2, (i + j) * map.tile_size.y / 2)
  end

  def draw(window, map)
    i = (x_c / Physics::UNIT).floor
    j = (y_c / Physics::UNIT).floor
    pos = @map_pos - Vector.new(map.cam.x + 10, map.cam.y + 20)
    window.draw_quad(pos.x, pos.y, 0xff993399,
                     pos.x + 20, pos.y, 0xff993399,
                     pos.x, pos.y + 20, 0xff993399,
                     pos.x + 20, pos.y + 20, 0xff993399, i + j + 1)
  end
end
