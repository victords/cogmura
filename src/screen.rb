require_relative 'iso_block'
require_relative 'graphic'
require_relative 'npc'
require_relative 'door'
require_relative 'character'

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
    t_w = Graphics::TILE_WIDTH
    t_h = Graphics::TILE_HEIGHT
    @map = Map.new(t_w, t_h, M_S, M_S, Graphics::SCR_W, Graphics::SCR_H, true)
    @map.set_camera(M_S / 4 * t_w, M_S / 4 * t_h)
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
      info, entrances, exits, doors, data = f.read.split('#')
      info = info.split(',')
      @tileset = Res.tileset(info[0], t_w / Graphics::SCALE, t_h / Graphics::SCALE)
      fill = info[1]

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end
      @doors = doors.split(';').map do |d|
        d = d.split(',')
        Door.new(d[0].to_i, d[1].to_i, d[2].to_i, d[3].to_f, d[4].to_f, d[5].to_i)
      end
      @doors.each do |d|
        d.on_open = method(:on_player_leave)
      end

      i = M_S / 2 - 1; j = 0
      data.split(';').each do |d|
        if d[0] == '_' && d[1] != '_'
          d[1..-1].to_i.times { i, j = next_tile(i, j) }
          next
        end

        if d[0] != '_'
          tile_type = d[0..1].to_i
          @tiles[i][j] = tile_type
        end

        case d[2]
        when '*'
          num_tiles = d[3..-1].to_i - 1
          num_tiles.times do
            i, j = next_tile(i, j)
            @tiles[i][j] = tile_type
          end
        when 'b' # textured block
          @blocks << IsoBlock.new(d[3].to_i, i, j)
        when 'w' # invisible block
          values = d[3..-1].split(',').map(&:to_f)
          @blocks << IsoBlock.new(nil, i, j, values[0], values[1], values[2])
        when 'g' # graphic (no collision)
          @graphics << Graphic.new(d[3].to_i, i, j)
        when 'n' # NPC
          @npcs << Npc.new(d[3].to_i, i, j)
        end
        i, j = next_tile(i, j)
      end
      next unless fill

      while j < M_S - 1 || j == M_S - 1 && i < M_S / 2 + 1
        @tiles[i][j] = fill.to_i
        i, j = next_tile(i, j)
      end
    end

    entrance = @entrances[entrance_index]
    @man = Character.new(entrance[0], entrance[1], entrance[2])
    @man.on_exit = method(:on_player_leave)

    @fading = :in
    @overlay_alpha = 255

    # TODO remove later
    @grid = Res.img(:grid)
  end

  def on_player_leave(exit_obj)
    @active_exit = exit_obj
    @fading = :out
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

    unless @fading == :out || @fading == :in && @overlay_alpha > 127
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
        n.update(npc_in_range ? nil : @man)
        npc_in_range = n if n.man_in_range
      end
    end

    @doors.each { |d| d.update(@man) }
  end

  def draw
    @map.foreach do |i, j, x, y|
      next unless @tiles[i][j]

      @tileset[@tiles[i][j]].draw(x, y, 0, Graphics::SCALE, Graphics::SCALE)
      @grid.draw(x, y, 0, Graphics::SCALE, Graphics::SCALE)
    end
    @blocks.each { |b| b.draw(@map, @man) }
    @doors.each { |d| d.draw(@map) }
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
