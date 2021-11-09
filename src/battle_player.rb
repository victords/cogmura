require_relative 'game'
require_relative 'constants'

class BattlePlayer < IsoGameObject
  SPEED = 4
  
  attr_reader :stats

  def initialize(col, row)
    super(col, row, 0, 20, 20, :char_cogmura, Vector.new(-14, -52), 6, 3, 2.8)
    @stats = Game.player_stats
    @img_index = 6
    @flip = true
    
    @start_pos = Vector.new(@x, @y)
  end
  
  def start_sequence(steps)
    @sequence = steps
    @sequence_step = 0
    @sequence_timer = @sequence[0][:timer] || 0
  end
  
  def attack_animation(target, on_attack, on_finish)
    start_sequence([
      {
        indices: [6, 7, 6, 8],
        flip: true,
        target: target
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
        callback: on_finish
      }
    ])
  end
  
  def update
    return unless @sequence
    
    step = @sequence[@sequence_step]
    move_free(step[:target], SPEED) if step[:target]
    animate(step[:indices], step[:interval] || 7)
    @sequence_timer -= 1 if @sequence_timer > 0
    if step[:timer] && @sequence_timer == 0 ||
       step[:target] && @speed.x == 0 && @speed.y == 0
      step[:callback]&.call
      @sequence_step += 1
      if @sequence_step == @sequence.size
        @sequence = nil
        set_animation(6)
        @flip = true
      else
        step = @sequence[@sequence_step]
        set_animation(step[:indices][0])
        @flip = step[:flip] || false
        @sequence_timer = step[:timer] || 0
      end
    end
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
