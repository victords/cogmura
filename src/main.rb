require 'minigl'
require_relative 'constants'
require_relative 'screen'
require_relative 'game'

include MiniGL

class Cogmura < GameWindow
  attr_reader :font

  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, false)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    Game.init

    @screen = Screen.new(1)
    @screen.on_exit = method(:change_screen)

    @font = TextHelper.new(
      ImageFont.new(:font, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"←→∞$ĞğİıÖöŞşÜü",
                    [6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                     6, 6, 6, 6, 6, 4, 6, 6, 2, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 4, 6, 6, 8, 6, 6, 6,
                     6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                     6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 2, 3, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 8, 8,
                     10, 6, 6, 6, 2, 2, 6, 6, 6, 6, 6, 6], 11, 4),
      1, 2, 2
    )
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

    @screen.update
  end

  def draw
    @screen.draw
  end
end

Cogmura.new.show
