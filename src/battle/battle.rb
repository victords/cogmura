require_relative 'player'
require_relative 'enemy'
require_relative '../inventory_item'
require_relative '../effect'
require_relative '../ui/panel_image'
require_relative '../ui/balloon'

include MiniGL

module Battle
  def self.start(player_spawn_point, enemy_type, enemy_spawn_points, &on_finish)
    Battle.new(player_spawn_point, enemy_type, enemy_spawn_points, &on_finish)
  end

  class Battle
    def initialize(player_spawn_point, enemy_type, enemy_spawn_points, &on_finish)
      @player = Player.new(player_spawn_point[0], player_spawn_point[1])
      @allies = [@player]
      @enemies = [Enemy.new(enemy_type, enemy_spawn_points[0][0], enemy_spawn_points[0][1], true)]
      @enemies[0].spawns.each do |e|
        break if @enemies.size >= enemy_spawn_points.size

        spawn_point = enemy_spawn_points[@enemies.size]
        @enemies << Enemy.new(e, spawn_point[0], spawn_point[1])
      end

      @player.stats.on_hp_change << method(:on_player_hp_change)
      @enemies.each do |e|
        e.stats.on_hp_change << lambda { |_, delta|
          on_enemy_hp_change(e, delta)
        }
      end

      # UI
      @panel = Panel.new(50, 50 + Graphics::V_OFFSET, 300, 10 + 4 * 54, (@labels = [
        Label.new(10, 10, Game.font, 'Attack', 0, 0, 0.5 * Graphics::SCALE, 0.5 * Graphics::SCALE),
        Label.new(10, 10 + 54, Game.font, 'Technique', 0, 0, 0.5 * Graphics::SCALE, 0.5 * Graphics::SCALE),
        Label.new(10, 10 + 2 * 54, Game.font, 'Item', 0, 0, 0.5 * Graphics::SCALE, 0.5 * Graphics::SCALE),
        Label.new(10, 10 + 3 * 54, Game.font, 'Flee', 0, 0, 0.5 * Graphics::SCALE, 0.5 * Graphics::SCALE)
      ]) + [
        @flee_balloon = Balloon.new(290, 6 + 3 * 54, '')
      ], :ui_panel, :tiled, false, Graphics::SCALE, Graphics::SCALE)
      @flee_balloon.visible = false
      @target_arrow = Res.imgs(:ui_arrow, 2, 2)[2]
      @effects = []
      set_flee_probability

      @state = :choosing_action
      @action_index = 0
      @enemy_index = 0
      @xp_earned = 0
      @money_earned = 0

      @on_finish = on_finish
    end

    def on_player_hp_change(_, delta)
      @effects << StatChangeEffect.new(:hp, delta, @player.screen_x + @player.img_size.x / 2, @player.screen_y)
    end

    def on_enemy_hp_change(enemy, delta)
      @effects << StatChangeEffect.new(:hp, delta, enemy.screen_x + enemy.img_size.x / 2, enemy.screen_y)
      if enemy.stats.hp.zero?
        @xp_earned += enemy.xp
        @money_earned += enemy.money
        @enemies.delete(enemy)
        set_flee_probability
      end
    end

    def set_flee_probability
      enemy_xp_sum = @enemies.map(&:xp).sum
      # probability of success starts at 100% and drops according to how much the XP
      # from the enemies represent from the amount needed to level up
      @flee_probability = (1 - (enemy_xp_sum.to_f / @player.stats.xp_delta)).clamp(0, 1)
      @flee_balloon.text = Game.text(:ui, :flee_prob, "#{(@flee_probability * 100).round}%")
    end

    def player_attack(enemy)
      @state = :animating
      @player.attack_animation(Vector.new(enemy.x - Physics::UNIT, enemy.y + Physics::UNIT), lambda {
        enemy.stats.take_damage([@player.stats.strength - enemy.stats.defense, 0].max)
      }, lambda {
        @state = :enemy_turn
      })
    end

    def enemy_attack(enemy)
      @state = :animating
      enemy.attack_animation(Vector.new(@player.x + Physics::UNIT, @player.y - Physics::UNIT), lambda {
        @player.stats.take_damage([enemy.stats.strength - @player.stats.defense, 0].max)
      }, lambda {
        @enemy_index += 1
        if @enemy_index >= @enemies.size
          @enemy_index = 0
          @state = :choosing_action
        else
          @state = :enemy_turn
        end
      })
    end

    def build_item_menu
      y = -44
      controls = @player.stats.items.map do |(item_type, amount)|
        y += 54
        name = Game.text(:ui, "item_#{item_type}")
        name_size = Game.font.text_width(name) * 0.5 * Graphics::SCALE
        name_scale = name_size > 200 ? 200.0 / name_size : 1
        [
          PanelImage.new(10, y, "icon_#{item_type}", Graphics::SCALE, Graphics::SCALE),
          Label.new(64, y, Game.font, name, 0, 0, 0.5 * Graphics::SCALE * name_scale, 0.5 * Graphics::SCALE * name_scale),
          Label.new(10, y, Game.font, amount.to_s, 0, 0, 0.5 * Graphics::SCALE, 0.5 * Graphics::SCALE, :top_right)
        ]
      end.flatten
      @item_panel = Panel.new(@panel.x + @panel.w, @panel.y + 2 * 54, 300, 10 + @player.stats.items.size * 54, controls,
                              :ui_panel, :tiled, true, Graphics::SCALE, Graphics::SCALE)
    end

    def finish(result)
      @player.stats.xp += @xp_earned
      @player.stats.money += @money_earned
      @on_finish.call(result)
    end

    def update
      @effects.reverse_each do |e|
        e.update
        @effects.delete(e) if e.destroyed
      end

      if @state == :animating || @state == :end
        @player.update
        @enemies.each(&:update)
        return
      elsif @player.stats.hp.zero?
        finish(:defeat)
        return
      elsif @enemies.empty?
        @player.victory_animation
        @effects << BattleVictory.new { finish(:victory) }
        @state = :end
        return
      end

      case @state
      when :choosing_action
        if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
          case @action_index
          when 0 # attack
            @targets = @enemies
            @target_callback = lambda { |target|
              player_attack(target)
            }
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
              build_item_menu
              @state = :choosing_item
              @action_index = 0
            else
              @effects << TextEffect.new(:no_items) { @state = :choosing_action }
              @state = :showing_message
            end
          when 3 # flee
            if rand <= @flee_probability
              finish(:fled)
            else
              @effects << TextEffect.new(:flee_fail) { @state = :enemy_turn }
              @state = :showing_message
            end
          end
        elsif KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
          @action_index += 1
          @action_index = 0 if @action_index >= @labels.size
          @flee_balloon.visible = @action_index == 3
        elsif KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
          @action_index -= 1
          @action_index = @labels.size - 1 if @action_index < 0
          @flee_balloon.visible = @action_index == 3
        end
      when :choosing_target
        if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
          @target_callback.call(@targets[@action_index])
        elsif KB.key_pressed?(Gosu::KB_RIGHT) || KB.key_held?(Gosu::KB_RIGHT) ||
              KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
          @action_index += 1
          @action_index = 0 if @action_index >= @targets.size
        elsif KB.key_pressed?(Gosu::KB_LEFT) || KB.key_held?(Gosu::KB_LEFT) ||
              KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
          @action_index -= 1
          @action_index = @targets.size - 1 if @action_index < 0
        end
      when :choosing_item
        if KB.key_pressed?(Gosu::KB_SPACE) || KB.key_pressed?(Gosu::KB_RETURN)
          item = InventoryItem.new(@player.stats.items.keys[@action_index])
          @targets = item.target_type == :ally ? @allies : @enemies
          @target_callback = lambda { |target|
            Game.player_stats.use_item(item, target.stats)
            @state = :enemy_turn
          }
          @state = :choosing_target
        elsif KB.key_pressed?(Gosu::KB_DOWN) || KB.key_held?(Gosu::KB_DOWN)
          @action_index += 1
          @action_index = 0 if @action_index >= @player.stats.items.size
        elsif KB.key_pressed?(Gosu::KB_UP) || KB.key_held?(Gosu::KB_UP)
          @action_index -= 1
          @action_index = @player.stats.items.size - 1 if @action_index < 0
        elsif KB.key_pressed?(Gosu::KB_ESCAPE) || KB.key_pressed?(Gosu::KB_BACKSPACE)
          @state = :choosing_action
          @action_index = 2
        end
      when :enemy_turn
        enemy = @enemies[@enemy_index]
        case enemy.choose_action
        when :attack
          enemy_attack(enemy)
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
        y = @panel.y + 10 + @action_index * 54
        G.window.draw_rect(@panel.x + 10, y, @panel.w - 20, 44, 0x33000000, ui_z)
      when :choosing_target
        target = @targets[@action_index]
        @target_arrow.draw(target.screen_x + target.img_size.x / 2 - 24, target.screen_y - 58, ui_z, Graphics::SCALE, Graphics::SCALE)
      when :choosing_item
        @panel.draw(255, ui_z)
        @item_panel.draw(255, ui_z)
        y = @item_panel.y + 10 + @action_index * 54
        G.window.draw_rect(@item_panel.x + 10, y, @item_panel.w - 20, 44, 0x33000000, ui_z)
      end
    end
  end
end
