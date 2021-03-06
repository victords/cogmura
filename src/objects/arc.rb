require_relative '../iso_game_object'
require_relative '../effect'

class Arc < IsoGameObject
  # type 0: along iso y-axis
  # type 1: angled (facing front)
  # type 2: along iso x-axis
  def initialize(type, col, row, layer, screen)
    layer ||= 0
    super(col, row, layer, Physics::UNIT, Physics::UNIT, :obj_arc, Vector.new(-10, -34), 3, 1)
    @img_index = type
    case type
    when 0
      screen.add_block(col - 0.25, row + 0.375, layer, 0.25, 0.25, 999)
      screen.add_block(col + 1, row + 0.375, layer, 0.25, 0.25, 999)
    when 1
      screen.add_block(col, row + 0.75, layer, 0.25, 0.25, 999)
      screen.add_block(col + 0.75, row, layer, 0.25, 0.25, 999)
    else
      screen.add_block(col + 0.375, row - 0.25, layer, 0.25, 0.25, 999)
      screen.add_block(col + 0.375, row + 1, layer, 0.25, 0.25, 999)
    end
    @screen = screen
  end

  def collide?
    false
  end

  def update(man)
    if man.intersect?(bounds)
      unless @active
        Game.player_stats.recover
        @screen.add_effect(RecoverEffect.new(@screen_x + @img[0].width / 2 * Graphics::SCALE - 21, @screen_y - 50))
        @active = true
      end
    else
      @active = false
    end
  end
end
