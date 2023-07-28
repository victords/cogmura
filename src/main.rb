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

    Game.init
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
