require_relative 'battle_enemy'

class Battle
  def initialize(enemy_type)
    @enemies = [BattleEnemy.new(enemy_type, true)]
    @enemies[0].spawns.each do |e|
      @enemies << BattleEnemy.new(e)
    end

    @enemies.each { |e| p e }
  end

  def update; end
end
