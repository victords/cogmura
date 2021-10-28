require_relative 'iso_game_object'
require_relative 'constants'

class ScreenEnemy < IsoGameObject
  TYPE_MAP = [
    [:bruk, 20, -8, -4, 1, 5, 2]
  ]
  FOLLOW_RANGE = 3 * Physics::UNIT
  MOVE_WAIT = 60
  MOVE_DURATION = 120
  SQRT2_2 = 0.7071
  DIRECTIONS = [
    [-SQRT2_2, SQRT2_2], [0, 1], [-1, 0], [SQRT2_2, SQRT2_2], [-SQRT2_2, -SQRT2_2],
    [SQRT2_2, -SQRT2_2], [1, 0], [0, -1]
  ]

  attr_reader :type, :name
  attr_writer :on_encounter

  def initialize(type, col, row, layer)
    layer ||= 0
    id, size, img_gap_x, img_gap_y, sprite_cols, sprite_rows, @speed_m = TYPE_MAP[type]
    super(col, row, layer, size, size, "char_#{id}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
    @type = id
    @name = id.to_s.split('_').map(&:capitalize).join(' ')

    @timer = 0
  end

  def update(man, floors, obstacles, ramps)
    if @speed_s
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
end
