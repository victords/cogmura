require_relative 'iso_game_object_with_args'

class RecoveryPad < IsoGameObjectWithArgs
  def initialize(col, row, layer, _args)
    super(col, row, layer, args, 20, 20, :obj_recoveryPad, Vector.new(-54, -12), 1, 1)
    @z_index = 100 * (col + row - 1) + 10 * layer
  end

  def collide?
    false;
  end

  def update(man, screen)
    if man.intersect?(bounds)
      unless @active
        Game.player_stats.recover
        screen.add_effect(RecoverEffect.new(@screen_x + @img[0].width / 2 - 30, @screen_y - 50))
        @active = true
      end
    else
      @active = false
    end
  end

  def draw(map, z_index = nil, alpha = 255)
    super(map, @z_index, alpha)
  end
end
