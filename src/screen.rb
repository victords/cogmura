require_relative 'iso_block'
require_relative 'graphic'
require_relative 'npc'

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
  M_S = Graphics::MAP_SIZE

  attr_writer :on_exit

  def initialize(id, entrance_index = 0)
    @map = Map.new(Graphics::TILE_WIDTH, Graphics::TILE_HEIGHT, M_S, M_S, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(M_S / 4 * Graphics::TILE_WIDTH, M_S / 4 * Graphics::TILE_HEIGHT)
    @tiles = Array.new(M_S) { Array.new(M_S) }
    @blocks = [
      IsoBlock.new(0, -1, M_S / 2 - 2),
      IsoBlock.new(0, M_S / 2, M_S - 1),
      IsoBlock.new(1, -1, M_S / 2),
      IsoBlock.new(1, M_S / 2, -1),
      IsoBlock.new(2, -0.5, M_S / 2 - 0.5),
      IsoBlock.new(2, M_S / 2 - 0.5, -0.5),
      IsoBlock.new(2, M_S / 2 - 0.5, M_S - 0.5),
      IsoBlock.new(2, M_S - 0.5, M_S / 2 - 0.5)
    ]
    @graphics = []
    @npcs = []

    File.open("#{Res.prefix}map/#{id}") do |f|
      info, entrances, exits, data = f.read.split('#')
      @tileset = Res.imgs("tile#{info}", 1, 7)

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end

      i = M_S / 2 - 1; j = 0
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
        when 'n'
          @npcs << Npc.new(d[3].to_i, i, j)
        end
        i, j = next_tile(i, j)
      end

      while j < M_S - 1 || j == M_S - 1 && i < M_S / 2 + 1
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
    obstacles = (@blocks + @npcs).select { |b| b.height > base_collide_level }
    @man.update(
      obstacles,
      @blocks.select { |b| b.height == @man.height_level },
      @man.grounded ? @blocks.select { |b| b.height == base_collide_level } : [],
      obstacles.map(&:ramps).compact.flatten,
      @exits.select { |e| e.z == @man.height_level }
    )

    npc_in_range = nil
    @npcs.each do |n|
      in_range = @man.grounded && npc_in_range.nil? && n.z == @man.z && n.in_range?(@man)
      n.man_in_range = in_range
      n.update
      npc_in_range = n if in_range
    end
  end

  def draw
    @map.foreach do |i, j, x, y|
      @tileset[@tiles[i][j]].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE) if @tiles[i][j]
    end
    @blocks.each { |b| b.draw(@map, @man) }
    @graphics.each { |g| g.draw(@map) }
    @man.draw(@map)
    @npcs.each { |n| n.draw(@map) }
    if @overlay_alpha > 0
      color = @overlay_alpha.round << 24
      G.window.draw_quad(0, 0, color, Graphics::SCR_W, 0, color, 0, Graphics::SCR_H, color, Graphics::SCR_W, Graphics::SCR_H, color, 10000)
    end
  end

  private

  def next_tile(i, j)
    i += 1
    if i >= M_S - (j >= M_S / 2 ? j - M_S / 2 : M_S / 2 - 1 - j)
      j += 1
      i = M_S / 2 - (j >= M_S / 2 ? M_S - j : j + 1)
    end
    [i, j]
  end
end
