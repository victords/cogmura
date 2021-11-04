require_relative 'game'
require_relative 'constants'

class BattlePlayer < IsoGameObject
  attr_reader :stats

  def initialize(col, row)
    super(col, row, 0, 20, 20, :char_cogmura, Vector.new(-22, -52), 3, 5, 2.8)
    @stats = Game.player_stats
  end

  def draw(map)
    super
    Game.text_helper.write_line(@stats.hp.to_s, @screen_x + @img_size.x / 2, @screen_y + @img_size.y, :center, 0xffffff, 255,
                                :border, 0, 2, 255, Graphics::UI_Z_INDEX)
  end
end
