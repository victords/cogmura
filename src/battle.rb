require_relative 'battle_player'
require_relative 'battle_enemy'
require_relative 'effect'

include MiniGL

class Battle
  def initialize(player_spawn_point, enemy_type, enemy_spawn_points, &on_finish)
    @player = BattlePlayer.new(player_spawn_point[0], player_spawn_point[1])
    @enemies = [BattleEnemy.new(enemy_type, enemy_spawn_points[0][0], enemy_spawn_points[0][1], true)]
    @enemies[0].spawns.each do |e|
      break if @enemies.size >= enemy_spawn_points.size

      spawn_point = enemy_spawn_points[@enemies.size]
      @enemies << BattleEnemy.new(e, spawn_point[0], spawn_point[1])
    end

    @player.stats.on_hp_change << method(:on_player_hp_change)
    @enemies.each do |e|
      e.stats.on_hp_change << lambda { |_, delta|
        on_enemy_hp_change(e, delta)
      }
    end

    # UI
    @panel = Panel.new(50, 50, 150, 22 * 4 + 5 * 5, @labels = [
      Label.new(10, 5, Game.font, 'Attack', 0, 0, 2, 2),
      Label.new(10, 5 + 27, Game.font, 'Technique', 0, 0, 2, 2),
      Label.new(10, 5 + 2 * 27, Game.font, 'Item', 0, 0, 2, 2),
      Label.new(10, 5 + 3 * 27, Game.font, 'Flee', 0, 0, 2, 2),
    ], :ui_panel, :tiled, true, Graphics::SCALE, Graphics::SCALE)
    @target_arrow = Res.img(:ui_arrowDown)
    @effects = []

    @state = :choosing_action
    @action_index = 0
    @enemy_index = 0

    @on_finish = on_finish
  end

  def on_player_hp_change(_, delta)
    @effects << StatChangeEffect.new(:hp, delta, @player.screen_x + @player.w / 2, @player.screen_y - 40)
  end

  def on_enemy_hp_change(enemy, delta)
    @effects << StatChangeEffect.new(:hp, delta, enemy.screen_x + enemy.w / 2, enemy.screen_y)
  end

  def player_attack(enemy)
    enemy.stats.take_damage([@player.stats.strength - enemy.stats.defense, 0].max)
  end

  def enemy_attack(enemy)
    @player.stats.take_damage([enemy.stats.strength - @player.stats.defense, 0].max)
  end

  def finish
    @player.stats.on_hp_change.delete(method(:on_player_hp_change))
    @on_finish.call
  end

  def update
    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.destroyed
    end

    case @state
    when :choosing_action
      if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
        case @action_index
        when 0 # attack
          @state = :choosing_target
          @action_index = 0
        when 1 # technique
          if @player.stats.techniques.any?
            @state = :choosing_technique
            @action_index = 0
          else
            @effects << TextEffect.new(:no_techniques) { @state = :choosing_action }
            @state = :showing_message
          end
        when 2 # item
          if @player.stats.items.any?
            @state = :choosing_item
            @action_index = 0
          else
            @effects << TextEffect.new(:no_items) { @state = :choosing_action }
            @state = :showing_message
          end
        when 3 # flee
          enemy_xp_sum = @enemies.map(&:xp).sum
          # probability of success starts at 100% and drops according to how much the XP
          # from the enemies represent from the amount needed to level up
          prob = (1 - (enemy_xp_sum.to_f / @player.stats.xp_to_next_level)).clamp(0, 1)
          if rand <= prob
            finish
          else
            @effects << TextEffect.new(:flee_fail) { @state = :enemy_turn }
            @state = :showing_message
          end
        end
      elsif KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
        @action_index += 1
        @action_index = 0 if @action_index >= @labels.size
      elsif KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
        @action_index -= 1
        @action_index = @labels.size - 1 if @action_index < 0
      end
    when :choosing_target
      if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
        player_attack(@enemies[@action_index])
        @state = :enemy_turn
      elsif KB.key_pressed?(Gosu::KB_RIGHT) || KB.key_held?(Gosu::KB_RIGHT) ||
            KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
        @action_index += 1
        @action_index = 0 if @action_index >= @enemies.size
      elsif KB.key_pressed?(Gosu::KB_LEFT) || KB.key_held?(Gosu::KB_LEFT) ||
            KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
        @action_index -= 1
        @action_index = @enemies.size - 1 if @action_index < 0
      end
    when :enemy_turn
      enemy = @enemies[@enemy_index]
      case enemy.choose_action
      when :attack
        enemy_attack(enemy)
      end
      @enemy_index += 1
      if @enemy_index >= @enemies.size
        @enemy_index = 0
        @state = :choosing_action
      end
    end
  end

  def draw(map)
    @player.draw(map)
    @enemies.each { |e| e.draw(map) }
    @effects.each(&:draw)

    ui_z = Graphics::UI_Z_INDEX
    case @state
    when :choosing_action
      @panel.draw(255, ui_z)
      label = @labels[@action_index]
      G.window.draw_rect(@panel.x + 5, label.y, @panel.w - 10, label.h, 0x33000000, ui_z)
    when :choosing_target
      enemy = @enemies[@action_index]
      @target_arrow.draw(enemy.screen_x + enemy.w / 2 - 12, enemy.screen_y - 34, ui_z, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
