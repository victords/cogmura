require_relative 'iso_game_object'

include MiniGL

class Character < IsoGameObject
  SPEED = 4
  SPEED_D = SPEED * 0.7071
  JUMP_SPEED = 9

  def initialize(i, j, w, h)
    super

    @speed_z = 0
  end

  def height_level
    (@z / Physics::V_UNIT).floor
  end

  def update(obstacles, floors)
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

    floor = height_level.zero? || floors.any? { |f| f.bounds.intersect?(bounds) }
    floor_z = height_level * Physics::V_UNIT

    if floor && @z == floor_z
      @speed_z = JUMP_SPEED if KB.key_pressed?(Gosu::KB_SPACE)
    else
      @speed_z -= G.gravity.y
    end

    if floor && @speed_z < 0 && @z + @speed_z < floor_z
      @speed_z = 0
      @z = height_level * Physics::V_UNIT
    else
      @z += @speed_z
    end
  end
end
