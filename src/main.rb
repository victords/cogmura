require 'minigl'
require_relative 'constants'
require_relative 'game'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, true)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'

    Game.init
  end

  def needs_cursor?
    false
  end

  def update
    KB.update

    # TODO remove later
    close if KB.key_pressed?(Gosu::KB_ESCAPE)

    Game.update
  end

  def draw
    Game.draw
  end
end

Cogmura.new.show
