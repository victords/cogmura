require_relative 'game'

class BattlePlayer < IsoGameObject
  attr_reader :stats

  def initialize(col, row)
    super(col, row, 0, 20, 20, :char_cogmura, Vector.new(-22, -52), 3, 5, 2.8)
    @stats = Game.player_stats
  end
end
