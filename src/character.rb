require_relative 'iso_game_object'

include MiniGL

class Character < IsoGameObject
  SPEED = 4
  SPEED_D = SPEED * 0.7071
  JUMP_SPEED = 9
  DIR_KEYS = [Gosu::KB_UP, Gosu::KB_RIGHT, Gosu::KB_DOWN, Gosu::KB_LEFT].freeze

  attr_reader :grounded

  def initialize(i, j)
    super(i, j, 20, 20, :cogmura, Vector.new(-22, -72), 3, 5)

    @speed_z = 0
  end

  def update(obstacles, floors, steps, ramps)
    up, rt, dn, lf = DIR_KEYS.map { |k| KB.key_down?(k) }
    p_up, p_rt, p_dn, p_lf = DIR_KEYS.map { |k| KB.key_pressed?(k) }
    r_up, r_rt, r_dn, r_lf = DIR_KEYS.map { |k| KB.key_released?(k) }
    speed =
      if up && !rt && !dn && !lf
        set_walk_animation(3, false) if p_up || r_rt || r_lf || r_dn
        Vector.new(-SPEED_D, -SPEED_D)
      elsif rt && !up && !dn && !lf
        set_walk_animation(6, true) if p_rt || r_up || r_dn || r_lf
        Vector.new(SPEED_D, -SPEED_D)
      elsif dn && !up && !rt && !lf
        set_walk_animation(0, false) if p_dn || r_rt || r_lf || r_up
        Vector.new(SPEED_D, SPEED_D)
      elsif lf && !up && !rt && !dn
        set_walk_animation(6, false) if p_lf || r_up || r_dn || r_rt
        Vector.new(-SPEED_D, SPEED_D)
      elsif up && rt && !dn && !lf
        set_walk_animation(12, true) if p_up || p_rt || r_dn || r_lf
        Vector.new(0, -SPEED)
      elsif rt && dn && !up && !lf
        set_walk_animation(9, true) if p_rt || p_dn || r_lf || r_up
        Vector.new(SPEED, 0)
      elsif dn && lf && !up && !rt
        set_walk_animation(9, false) if p_dn || p_lf || r_up || r_rt
        Vector.new(0, SPEED)
      elsif lf && up && !rt && !dn
        set_walk_animation(12, false) if p_lf || p_up || r_rt || r_dn
        Vector.new(-SPEED, 0)
      else
        set_animation(3 * (@img_index / 3))
        Vector.new(0, 0)
      end
    move(speed, obstacles, ramps, true)

    @floor = height_level.zero? || floors.find { |f| f.intersect?(bounds) }
    floor_z = height_level * Physics::V_UNIT
    if @floor && @z == floor_z
      @speed_z = JUMP_SPEED if KB.key_pressed?(Gosu::KB_SPACE)
    else
      @speed_z -= G.gravity.y
    end

    if @floor && @speed_z < 0 && @z + @speed_z < floor_z
      @speed_z = 0
      @z = height_level * Physics::V_UNIT
    else
      @z += @speed_z
    end

    @grounded = @floor && @z == floor_z
    step = steps.find { |s| s.intersect?(bounds) }
    @z += Physics::V_UNIT if step && @grounded

    animate(@indices, 7)
  end

  def set_walk_animation(index, flip)
    set_animation(index)
    @indices = [index, index + 1, index, index + 2]
    @flip = flip
  end

  def draw(map)
    super(map, @flip ? :horiz : nil, @floor && @floor.is_a?(IsoBlock) && @floor.z_index)
  end
end
