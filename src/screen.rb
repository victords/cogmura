require_relative 'iso_tex_block'

include MiniGL

class Screen
  attr_reader :blocks

  def initialize(id)
    @map = Map.new(Graphics::TILE_WIDTH, Graphics::TILE_HEIGHT, 40, 40, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(10 * Graphics::TILE_WIDTH, 10 * Graphics::TILE_HEIGHT)
    @tiles = Array.new(40) { Array.new(40) }
    @blocks = []
    File.open("#{Res.prefix}map/#{id}") do |f|
      info, data = f.read.split('#')
      @tileset = Res.imgs("tile#{info}", 1, 2)

      i = 19; j = 0
      data.split(';').each do |d|
        tile_type = d[0..1].to_i
        @tiles[i][j] = tile_type
        case d[2]
        when '*'
          num_tiles = d[3..-1].to_i - 1
          num_tiles.times do
            i, j = next_tile(i, j)
            @tiles[i][j] = tile_type
          end
        when 'b'
          @blocks << IsoBlock.new(d[3], i, j, d[4].to_i, d[5])
        when 't'
          @blocks << IsoTexBlock.new(d[3].to_i, i, j)
        end
        i, j = next_tile(i, j)
      end

      while j < 39 || j == 39 && i < 21
        @tiles[i][j] = 0
        i, j = next_tile(i, j)
      end
    end

    @man = Character.new(11, 11)
  end

  def update
    base_collide_level = @man.grounded ? @man.height_level + 1 : @man.height_level
    obstacles = @blocks.select { |b| b.height > base_collide_level }
    @man.update(
      obstacles,
      @blocks.select { |b| b.height == @man.height_level },
      @man.grounded ? @blocks.select { |b| b.height == base_collide_level } : [],
      obstacles.map(&:ramps).compact.flatten
    )
  end

  def draw
    @map.foreach do |i, j, x, y|
      @tileset[@tiles[i][j]].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE) if @tiles[i][j]
    end
    @blocks.each { |b| b.draw(@map, @man) }
    @man.draw(@map)
  end

  private

  def next_tile(i, j)
    i += 1
    if i >= 40 - (j >= 20 ? j - 20 : 19 - j)
      j += 1
      i = 20 - (j >= 20 ? 40 - j : j + 1)
    end
    [i, j]
  end
end
