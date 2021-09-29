require 'minigl'
require_relative 'constants'
require_relative 'character'
require_relative 'iso_block'
require_relative 'iso_tex_block'

include MiniGL

class Cogmura < GameWindow
  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, false)

    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Res.retro_images = true

    @tile = Res.imgs(:tile1, 1, 2)
    @map = Map.new(Graphics::TILE_WIDTH, Graphics::TILE_HEIGHT, 40, 40, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(10 * Graphics::TILE_WIDTH, 10 * Graphics::TILE_HEIGHT)

    @man = Character.new(11, 11)
    @blocks = [
      IsoBlock.new(14, 15, 2),
      IsoBlock.new(15, 15, 1),
      IsoBlock.new(14, 14, 4),
      IsoBlock.new(15, 14, 4),
      IsoTexBlock.new(11, 18, 2, 3, 3, :house1, Vector.new(-6, -16))
    ]
  end

  def update
    KB.update

    toggle_fullscreen if KB.key_pressed?(Gosu::KB_F4)
    close if KB.key_pressed?(Gosu::KB_ESCAPE)

    @man.update(
      @blocks.select { |b| b.height > @man.height_level + 1 },
      @blocks.select { |b| b.height == @man.height_level },
      @blocks.select { |b| b.height == @man.height_level + 1 },
    )
  end

  def draw
    @map.foreach do |i, j, x, y|
      @tile[0].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE)
    end
    @blocks.each { |b| b.draw(@map) }
    @man.draw(@map)
  end
end

Cogmura.new.show