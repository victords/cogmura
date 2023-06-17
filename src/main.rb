require 'minigl'
require_relative 'constants'
require_relative 'screen'
require_relative 'game'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(1920, 1080, true)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    start
  end

  def start
    Game.init

    @screen = Screen.new(1)
    @screen.on_exit = method(:change_screen)
  end

  def change_screen(exit_obj)
    @screen = Screen.new(exit_obj.dest_scr, exit_obj.dest_entr)
    @screen.on_exit = method(:change_screen)
  end

  def draw_rect(x, y, w, h, color, z_index)
    draw_quad(x, y, color, x + w, y, color, x, y + h, color, x + w, y + h, color, z_index)
  end

  def update
    KB.update

    toggle_fullscreen if KB.key_pressed?(Gosu::KB_F4)
    close if KB.key_pressed?(Gosu::KB_ESCAPE)
    start if KB.key_pressed?(Gosu::KB_R)

    @screen.update unless Game.over?
  end

  def draw
    if Game.over?
      Game.text_helper.write_line('Game Over', Graphics::SCR_W / 2, Graphics::SCR_H / 2 - 22, :center, 0xffffff, 255, nil, 0, 0, 0, 0, 4, 4)
    else
      @screen.draw
    end
  end
end

Cogmura.new.show
