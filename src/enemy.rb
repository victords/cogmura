require_relative 'iso_game_object'
require_relative 'constants'

class Enemy < IsoGameObject
  FOLLOW_RANGE = 3 * Physics::UNIT
  MOVE_WAIT = 30
  MOVE_DURATION = 60
  SQRT2_2 = 0.7071
  DIRECTIONS = [
    [-SQRT2_2, SQRT2_2], [0, 1], [-1, 0], [SQRT2_2, SQRT2_2], [-SQRT2_2, -SQRT2_2],
    [SQRT2_2, -SQRT2_2], [1, 0], [0, -1]
  ]

  attr_reader :type, :name
  attr_writer :on_encounter

  def initialize(type, col, row, layer)
    layer ||= 0
    id, size, img_gap_x, img_gap_y, sprite_cols, sprite_rows, @speed_m = ENEMY_TYPE_MAP[type]
    super(col, row, layer, size, size, "char_#{id}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @type = id
    @name = id.to_s.split('_').map(&:capitalize).join(' ')

    @timer = 0
    @active = true
    @active_timer = 0
  end

  def set_inactive
    @active = false
    @blink = false
  end

  def set_active(delay = 0)
    @active_timer = delay
    @blink = true
  end

  def update(man, floors, obstacles, ramps)
    return

    if @blink
      @active_timer -= 1 if @active_timer > 0
      @active = true if @active_timer <= 0
    end
    return unless @active

    d = plane_distance(man)
    if d <= FOLLOW_RANGE
      d_x = man.x - @x; d_y = man.y - @y
      speed_x = @speed_m * d_x / d
      speed_y = @speed_m * d_y / d
      move(Vector.new(speed_x, speed_y), obstacles, ramps, true)
      angle = 180 * Math.atan2(d_y, d_x) / Math::PI
      if angle >= -22.5 && angle < 22.5
        @img_index = 1; @flip = true
      elsif angle >= 22.5 && angle < 67.5
        @img_index = 3; @flip = false
      elsif angle >= 67.5 && angle < 112.5
        @img_index = 1; @flip = false
      elsif angle >= 112.5 && angle < 157.5
        @img_index = 0; @flip = false
      elsif angle >= 157.5 || angle < -157.5
        @img_index = 2; @flip = false
      elsif angle >= -157.5 && angle < -112.5
        @img_index = 4; @flip = false
      elsif angle >= -112.5 && angle < -67.5
        @img_index = 2; @flip = true
      else
        @img_index = 0; @flip = true
      end
      if @speed_s
        @speed_s = nil
        @timer = MOVE_WAIT
      end
    elsif @speed_s
      move(@speed_s, obstacles, ramps, true)
      @timer += 1
      if @timer >= MOVE_DURATION
        @speed_s = nil
        @timer = 0
      end
    else
      @timer += 1
      if @timer >= MOVE_WAIT
        index = rand(7)
        @img_index = index % 5
        @flip = index >= 5
        @speed_s = Vector.new(DIRECTIONS[index][0] * @speed_m, DIRECTIONS[index][1] * @speed_m)
        @timer = 0
      end
    end

    return unless man.bounds.intersect?(bounds) && man.vert_intersect?(self)

    @on_encounter.call(self)
  end

  def draw(map)
    alpha = @active_timer > 0 ? (@active_timer / 10) % 2 * 255 : 255
    super(map, nil, alpha)
  end
end
