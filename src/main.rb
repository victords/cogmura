require 'minigl'
require_relative 'constants'
require_relative 'iso_game_object'
require_relative 'iso_block'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, false)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    @tile = Res.imgs(:tile1, 1, 2)
    @map = Map.new(Graphics::TILE_WIDTH, Graphics::TILE_HEIGHT, 20, 20, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(5 * Graphics::TILE_WIDTH, 5 * Graphics::TILE_HEIGHT)

    @man = IsoGameObject.new(5, 5, 20, 20)
    @blocks = Array.new(@map.size.x) do
      Array.new(@map.size.y)
    end
    @obstacles = []
    add_block(6, 7, :block1)
    add_block(7, 7, :step1)
  end

  def add_block(i, j, type)
    @blocks[i][j] = IsoBlock.new(i, j, type)
    @obstacles << @blocks[i][j]
  end

  def update
    KB.update

    toggle_fullscreen if KB.key_pressed?(Gosu::KB_F4)
    close if KB.key_pressed?(Gosu::KB_ESCAPE)

    @man.update(@obstacles, @map)
  end

  def draw
    @map.foreach do |i, j, x, y|
      if @blocks[i][j]
        @blocks[i][j].draw(x, y, i + j + 1)
      else
        index = i == 2 && j == 3 ? 1 : 0
        @tile[index].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE)
      end
    end
    @man.draw(self, @map)
  end
end

Cogmura.new.show
