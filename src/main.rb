require 'minigl'
require_relative 'constants'
require_relative 'character'
require_relative 'screen'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, false)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    @screen = Screen.new(1)
    @screen.on_player_exit = method(:change_screen)
  end

  def update
    KB.update

    toggle_fullscreen if KB.key_pressed?(Gosu::KB_F4)
    close if KB.key_pressed?(Gosu::KB_ESCAPE)

    @screen.update
  end

  def change_screen(exit)
    @screen = Screen.new(exit.dest_scr, exit.dest_entr)
    @screen.on_player_exit = method(:change_screen)
  end

  def draw
    @screen.draw
  end
end

Cogmura.new.show
