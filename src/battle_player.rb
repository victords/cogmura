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
    c_x = @screen_x + @img_size.x / 2
    base_y = @screen_y + @img_size.y + 4
    G.window.draw_rect(c_x - 32, base_y, 64, 14, 0xff000000, Graphics::UI_Z_INDEX)
    G.window.draw_rect(c_x - 30, base_y + 2, 60, 10, 0xffff0000, Graphics::UI_Z_INDEX)
    G.window.draw_rect(c_x - 30, base_y + 2, ((@stats.hp.to_f / @stats.max_hp) * 60).round, 10,
                       0xff00ff00, Graphics::UI_Z_INDEX)
    Game.text_helper.write_line("#{@stats.hp}/#{@stats.max_hp}", c_x, base_y + 16, :center, 0xffffff, 255,
                                :border, 0, 2, 255, Graphics::UI_Z_INDEX)
  end
end
