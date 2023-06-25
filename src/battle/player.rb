require_relative '../game'
require_relative '../constants'
require_relative '../animation'

module Battle
  class Player < IsoGameObject
    include Animation

    SPEED = 4

    attr_reader :stats

    def initialize(col, row)
      super(col, row, 0, 20, 20, :char_cogmura, Vector.new(-38, -128), 5, 4, 2.8)
      @stats = Game.player_stats
      @img_index = 6
      @flip = true

      @start_pos = Vector.new(@x, @y)
    end

    def attack_animation(target, on_attack, on_finish)
      start_sequence(
        {
          indices: [6, 7, 6, 8],
          flip: true,
          target: target,
          speed: SPEED
        },
        {
          indices: [15],
          timer: 60,
          callback: on_attack
        },
        {
          indices: [16],
          timer: 60
        },
        {
          indices: [6, 7, 6, 8],
          target: @start_pos,
          speed: SPEED,
          callback: lambda {
            on_finish.call
            set_animation(6)
            @flip = true
          }
        }
      )
    end

    def victory_animation
      @img_index = 18
    end

    def update
      update_sequence
    end

    def draw(map)
      super
      return if @sequence

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
end
