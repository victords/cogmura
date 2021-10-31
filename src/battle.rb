require_relative 'battle_enemy'
require_relative 'effect'

include MiniGL

class Battle
  def initialize(enemy_type, spawn_points)
    @enemies = [BattleEnemy.new(enemy_type, spawn_points[0][0], spawn_points[0][1], true)]
    @enemies[0].spawns.each do |e|
      break if @enemies.size >= spawn_points.size

      spawn_point = spawn_points[@enemies.size]
      @enemies << BattleEnemy.new(e, spawn_point[0], spawn_point[1])
    end

    # UI
    @panel = Panel.new(50, 50, 150, 22 * 4 + 5 * 5, @labels = [
      Label.new(10, 5, Game.font, 'Attack', 0, 0, 2, 2),
      Label.new(10, 5 + 27, Game.font, 'Technique', 0, 0, 2, 2),
      Label.new(10, 5 + 2 * 27, Game.font, 'Item', 0, 0, 2, 2),
      Label.new(10, 5 + 3 * 27, Game.font, 'Flee', 0, 0, 2, 2),
    ], :ui_panel, :tiled, true, 2, 2)
    @action_index = 0
    @effects = []

    @state = :choosing_action
  end

  def update
    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.destroyed
    end

    case @state
    when :showing_message
      @timer -= 1
      @state = :choosing_action if @timer == 0
    when :choosing_action
      if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
        case @action_index
        when 0 # attack
          @state = :choosing_target
        when 1 # technique
          if Game.player_stats.techniques.any?
            @state = :choosing_technique
            @action_index = 0
          else
            @effects << TextEffect.new(:no_techniques)
            @state = :showing_message
            @timer = 120
          end
        end
      elsif KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
        @action_index += 1
        @action_index = 0 if @action_index >= @labels.size
      elsif KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
        @action_index -= 1
        @action_index = @labels.size - 1 if @action_index < 0
      end
    end
  end

  def draw(map)
    @enemies.each { |e| e.draw(map) }
    @effects.each(&:draw)
    return if @state == :showing_message

    ui_z = Graphics::UI_Z_INDEX
    @panel.draw(255, ui_z)
    label = @labels[@action_index]
    G.window.draw_rect(@panel.x + 5, label.y, @panel.w - 10, label.h, 0x33000000, ui_z)
  end
end
