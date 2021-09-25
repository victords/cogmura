require 'minigl'
require_relative 'iso_game_object'
require_relative 'iso_block'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(1280, 720, false)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    @tile = Res.imgs(:tile1, 1, 2)
    @map = Map.new(60, 30, 10, 10, self.width, self.height, true)

    @man = IsoGameObject.new(0, 0, 20, 20)
    @blocks = Array.new(@map.size.x) do
      Array.new(@map.size.y)
    end
    @obstacles = []
    add_block(2, 7, :block1)
    add_block(3, 7, :step1)
  end

  def add_block(i, j, type)
    @blocks[i][j] = IsoBlock.new(i, j, type)
    @obstacles << @blocks[i][j]
  end

  def update
    KB.update

    toggle_fullscreen if KB.key_pressed?(Gosu::KB_F4)

    @man.update(@obstacles, @map)
  end

  def draw
    @map.foreach do |i, j, x, y|
      if @blocks[i][j]
        @blocks[i][j].draw(x, y, i + j + 1)
      else
        index = i == 2 && j == 3 ? 1 : 0
        @tile[index].draw(x, y, 0, 3, 3)
      end
    end
    @man.draw(self, @map)
  end
end

Cogmura.new.show
