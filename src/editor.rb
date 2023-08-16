require 'minigl'
require_relative 'constants'
require_relative 'game'

include MiniGL

class EditorScreen < Screen
  def initialize(id)
    super
    @fading = nil
    @overlay_alpha = 0
    @grid = Res.img(:grid)
  end
end

class Editor < GameWindow
  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, true)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Game.init
    @screen = EditorScreen.new(1)
  end

  def update
    KB.update
    Mouse.update

    close if KB.key_pressed?(Gosu::KB_ESCAPE)
  end

  def draw
    @screen.draw
    G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)
    G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)
  end
end

Editor.new.show
