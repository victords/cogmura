require_relative 'battle_enemy'

class Battle
  def initialize(enemy_type, spawn_points)
    @enemies = [BattleEnemy.new(enemy_type, spawn_points[0][0], spawn_points[0][1], true)]
    @enemies[0].spawns.each do |e|
      break if @enemies.size >= spawn_points.size

      spawn_point = spawn_points[@enemies.size]
      @enemies << BattleEnemy.new(e, spawn_point[0], spawn_point[1])
    end
  end

  def update; end

  def draw(map)
    @enemies.each { |e| e.draw(map) }
  end
end
