require_relative 'iso_block'
require_relative 'graphic'
require_relative 'npc'
require_relative 'door'
require_relative 'screen_item'
require_relative 'screen_enemy'
require_relative 'character'
require_relative 'effect'

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
      IsoBlock.new(nil, -1, M_S / 2 - 2, -999, 16, 1, 999, true),
      IsoBlock.new(nil, M_S / 2, M_S - 1, -999, 16, 1, 999, true),
      IsoBlock.new(nil, -1, M_S / 2, -999, 1, 16, 999, true),
      IsoBlock.new(nil, M_S / 2, -1, -999, 1, 16, 999, true),
      IsoBlock.new(nil, -0.5, M_S / 2 - 0.5, -999),
      IsoBlock.new(nil, M_S / 2 - 0.5, -0.5, -999),
      IsoBlock.new(nil, M_S / 2 - 0.5, M_S - 0.5, -999),
      IsoBlock.new(nil, M_S - 0.5, M_S / 2 - 0.5, -999)
    ]
    @doors = []
    @graphics = []
    @npcs = []
    @items = []
    @enemies = []
    @effects = []

    File.open("#{Res.prefix}map/#{id}") do |f|
      info, entrances, exits, objects, tiles = f.read.split('#')
      info = info.split(',')
      @tileset = Res.tileset(info[0], t_w / Graphics::SCALE, t_h / Graphics::SCALE)
      fill = info[1]

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end

      objects.split(';').each do |o|
        d = o[1..].split(',')
        d = d.map(&:to_i) unless o[0] == 'd'
        case o[0]
        when 'b' # textured block
          @blocks << IsoBlock.new(d[0], d[1], d[2], d[3] || 0)
        when 'w' # invisible block
          @blocks << IsoBlock.new(nil, d[0], d[1], 0, d[2], d[3])
        when 'd'
          @doors << (door = Door.new(d[0].to_i, d[1].to_i, d[2].to_i, d[3].to_f, d[4].to_f, d[5].to_i))
          door.on_open = method(:on_player_leave)
        when 'g'
          @graphics << Graphic.new(d[0], d[1], d[2])
        when 'n'
          @npcs << Npc.new(d[0], d[1], d[2])
        when 'i'
          @items << (item = ScreenItem.new(d[0], d[1], d[2]))
          item.on_picked_up = method(:on_item_picked_up)
        when 'e'
          @enemies << (enemy = ScreenEnemy.new(d[0], d[1], d[2]))
          enemy.on_encounter = method(:on_enemy_encounter)
        end
      end

      i = M_S / 2 - 1; j = 0
      tiles.split(';').each do |d|
        if d[0] == '_'
          d[1..].to_i.times { i, j = next_tile(i, j) }
          next
        end

        tile_type = d.to_i
        index = d.index('*')
        num_tiles = index ? d[(index + 1)..].to_i : 1
        num_tiles.times do
          @tiles[i][j] = tile_type
          i, j = next_tile(i, j)
        end
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

  def on_item_picked_up(item)
    Game.player_stats.add_item(item)
    @effects << ItemPickUpEffect.new(item)
  end

  def on_enemy_encounter(enemy)
    puts "fight with #{enemy.name}"
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
      obstacles = (@blocks + @npcs).select do |b|
        b.z + b.height > @man.z && @man.z + @man.height > b.z &&
          !(@man.grounded && b.height_level == @man.height_level + 1)
      end
      @man.update(
        obstacles,
        @blocks.select { |b| b.height_level == @man.height_level },
        @blocks.select { |b| b.z >= @man.z + @man.height },
        @man.grounded ? @blocks.select { |b| b.height_level == @man.height_level + 1 } : [],
        obstacles.map(&:ramps).compact.flatten,
        @exits.select { |e| e.z == @man.height_level }
      )

      npc_in_range = nil
      @npcs.each do |n|
        n.update(npc_in_range ? nil : @man)
        npc_in_range = n if n.man_in_range
      end

      @items.reverse_each do |item|
        item.update(@man)
        @items.delete(item) if item.destroyed
      end

      @enemies.each { |e| e.update(@man) }
    end

    @doors.each { |d| d.update(@man) }

    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.destroyed
    end
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
    @items.each { |i| i.draw(@map) }
    @enemies.each { |e| e.draw(@map) }
    @effects.each(&:draw)
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
