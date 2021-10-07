require_relative 'iso_block'
require_relative 'graphic'

include MiniGL

class Exit < Rectangle
  attr_reader :dest_scr, :dest_entr, :z

  def initialize(dest_scr, dest_entr, i, j, z)
    super(i * Physics::UNIT, j * Physics::UNIT, Physics::UNIT, Physics::UNIT)
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    @z = z
  end
end

class Screen
  FADE_DURATION = 30.0

  attr_writer :on_exit

  def initialize(id, entrance_index = 0)
    @map = Map.new(Graphics::TILE_WIDTH, Graphics::TILE_HEIGHT, 40, 40, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(10 * Graphics::TILE_WIDTH, 10 * Graphics::TILE_HEIGHT)
    @tiles = Array.new(40) { Array.new(40) }
    @blocks = [
      IsoBlock.new(0, -1, 18),
      IsoBlock.new(0, 20, 39),
      IsoBlock.new(1, -1, 20),
      IsoBlock.new(1, 20, -1),
      IsoBlock.new(2, -0.5, 19.5),
      IsoBlock.new(2, 19.5, -0.5),
      IsoBlock.new(2, 19.5, 39.5),
      IsoBlock.new(2, 39.5, 19.5)
    ]
    @graphics = []

    File.open("#{Res.prefix}map/#{id}") do |f|
      info, entrances, exits, data = f.read.split('#')
      @tileset = Res.imgs("tile#{info}", 1, 2)

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end

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
          @blocks << IsoBlock.new(d[3].to_i, i, j)
        when 'g'
          @graphics << Graphic.new(d[3].to_i, i, j)
        end
        i, j = next_tile(i, j)
      end

      while j < 39 || j == 39 && i < 21
        @tiles[i][j] = 0
        i, j = next_tile(i, j)
      end
    end

    entrance = @entrances[entrance_index]
    @man = Character.new(entrance[0], entrance[1], entrance[2])
    @man.on_exit = lambda { |exit|
      @active_exit = exit
      @fading = :out
    }

    @fading = :in
    @overlay_alpha = 255
  end

  def update
    if @fading == :in
      @overlay_alpha -= 255 / FADE_DURATION
      if @overlay_alpha <= 0
        @overlay_alpha = 0
        @fading = nil
      end
    elsif @fading == :out
      @overlay_alpha += 255 / FADE_DURATION
      if @overlay_alpha >= 255
        @overlay_alpha = 255
        @on_exit.call(@active_exit)
      end
    end

    return if @fading == :out || @fading == :in && @overlay_alpha > 127

    base_collide_level = @man.grounded ? @man.height_level + 1 : @man.height_level
    obstacles = @blocks.select { |b| b.height > base_collide_level }
    @man.update(
      obstacles,
      @blocks.select { |b| b.height == @man.height_level },
      @man.grounded ? @blocks.select { |b| b.height == base_collide_level } : [],
      obstacles.map(&:ramps).compact.flatten,
      @exits.select { |e| e.z == @man.height_level }
    )
  end

  def draw
    @map.foreach do |i, j, x, y|
      @tileset[@tiles[i][j]].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE) if @tiles[i][j]
    end
    @blocks.each { |b| b.draw(@map, @man) }
    @graphics.each { |g| g.draw(@map) }
    @man.draw(@map)
    if @overlay_alpha > 0
      color = @overlay_alpha.round << 24
      G.window.draw_quad(0, 0, color, Graphics::SCR_W, 0, color, 0, Graphics::SCR_H, color, Graphics::SCR_W, Graphics::SCR_H, color, 10000)
    end
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
