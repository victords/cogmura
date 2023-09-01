require_relative 'iso_block'
require_relative 'npc'
require_relative 'item'
require_relative 'enemy'
require_relative 'character'
require_relative 'effect'
require_relative 'battle/battle'
require_relative 'objects'

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
  T_W = Graphics::TILE_WIDTH
  T_H = Graphics::TILE_HEIGHT

  OBJECT_CLASSES = {
    0 => Graphic,
    1 => Door,
    2 => Letter,
    3 => Bed,
    4 => Box,
    5 => RecoveryPad,
  }.freeze

  attr_writer :on_exit

  def initialize(id, entrance_index = 0)
    init_props
    load_from_file(id)
    init_player(entrance_index)
    init_transition

    # @grid = Res.img(:grid)
  end

  def battle?
    !!@battle
  end

  def add_effect(effect)
    @effects << effect
  end

  # EVENTS ####################################################################

  def on_player_leave(exit_obj)
    @fading = :out
    @on_fade_end = lambda do
      @on_exit.call(exit_obj)
    end
  end

  def on_item_picked_up(item_key)
    Game.player_stats.add_item(item_key)
    @effects << ItemPickUpEffect.new(item_key)
  end

  def on_money_picked_up(amount)
    Game.player_stats.money += amount
    @effects << MoneyPickUpEffect.new(amount)
  end

  def on_enemy_encounter(enemy)
    enemy.set_inactive
    @man.active = false
    @effects << BattleSplash.new do
      @battle = Battle.start(@spawn_points[0], enemy.type, @spawn_points[1..]) do |result|
        @battle = nil
        @man.active = true
        case result
        when :fled
          enemy.set_active(120)
        when :victory
          @enemies.delete(enemy)
        when :defeat
          Game.game_over
        end
      end
    end
  end

  def on_message_read(type, text_id)
    Game.set_message(type, text_id, [:close])
  end

  def on_sleep_confirm(price)
    @sleep_price = price
    if price > 0
      Game.set_message(:confirm, :sleep_paid, [:yes, :no], method(:on_sleep), price)
    else
      Game.set_message(:confirm, :sleep_free, [:yes, :no], method(:on_sleep))
    end
  end

  def on_sleep(option)
    return unless option == :yes

    if Game.player_stats.money < @sleep_price
      Game.set_message(:confirm, :not_enough_money, [:ok])
      return
    end

    @fading = :out
    @on_fade_end = lambda do
      Game.player_stats.recover
      @fading = :in
    end
  end

  #############################################################################

  def update
    battle_start = false
    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.destroyed
      battle_start = true if e.is_a?(BattleSplash) && !e.destroyed
    end
    return if battle_start

    if @battle
      @battle.update
      return
    end

    case @fading
    when :in
      @overlay_alpha -= 255 / FADE_DURATION
      if @overlay_alpha <= 0
        @overlay_alpha = 0
        @fading = nil
      end
    when :out
      @overlay_alpha += 255 / FADE_DURATION
      if @overlay_alpha >= 255
        @overlay_alpha = 255
        @on_fade_end.call
      end
    end

    unless @fading == :out || @fading == :in && @overlay_alpha > 127
      obstacles = (@blocks + @npcs + @objects.select(&:collide?)).select do |b|
        @man.vert_intersect?(b) && !(@man.grounded && b.height_level == @man.height_level + 1)
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

      @enemies.each do |e|
        floors = @blocks.select { |b| b.height_level == e.height_level }
        obstacles = @blocks.select { |b| e.vert_intersect?(b) }
        ramps = obstacles.map(&:ramps).compact.flatten
        e.update(@man, floors, obstacles, ramps)
      end
    end

    @objects.each { |d| d.update(@man, self) }
  end

  def draw
    @map.foreach do |i, j, x, y|
      next unless @tiles[i][j]

      @tileset[@tiles[i][j]].draw(x, y, 0)
      @grid.draw(x, y, 0) if @grid
    end
    @blocks.each { |b| b.draw(@map, @man) }
    @objects.each { |o| o.draw(@map) unless o.drawn? }

    if @battle
      @battle.draw(@map)
    else
      @man.draw(@map)
      @npcs.each { |n| n.draw(@map) }
      @items.each { |i| i.draw(@map) }
      @enemies.each { |e| e.draw(@map) }
      @effects.each(&:draw)
    end

    return unless @overlay_alpha > 0

    color = @overlay_alpha.round << 24
    G.window.draw_rect(0, 0, G.window.width, G.window.height, color, Graphics::UI_Z_INDEX)
  end

  protected

  def init_props
    @map = Map.new(T_W, T_H, M_S, M_S, M_S * T_W, M_S * T_H, true)
    @map.set_camera(M_S / 4.0 * T_W, M_S / 4.0 * T_H - Graphics::V_OFFSET)

    @tiles = Array.new(M_S) { Array.new(M_S) }
    @blocks = [
      IsoBlock.new(nil, -1, M_S / 2 - 2, -100, 16, 1, 999, true),
      IsoBlock.new(nil, M_S / 2, M_S - 1, -100, 16, 1, 999, true),
      IsoBlock.new(nil, -1, M_S / 2, -100, 1, 16, 999, true),
      IsoBlock.new(nil, M_S / 2, -1, -100, 1, 16, 999, true),
      IsoBlock.new(nil, -0.5, M_S / 2 - 0.5, -100),
      IsoBlock.new(nil, M_S / 2 - 0.5, -0.5, -100),
      IsoBlock.new(nil, M_S / 2 - 0.5, M_S - 0.5, -100),
      IsoBlock.new(nil, M_S - 0.5, M_S / 2 - 0.5, -100)
    ]
    @objects = []
    @npcs = []
    @items = []
    @enemies = []
    @effects = []
  end

  def load_from_file(id)
    File.open("#{Res.prefix}screen/#{id}") do |f|
      info, entrances, exits, spawn_points, objects, tiles = f.read.split('#')
      info = info.split(',')
      @tileset = Res.tileset(info[0], T_W, T_H)
      fill = info[1]

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end
      @spawn_points = spawn_points.split(';').map { |p| p.split(',').map(&:to_i) }

      objects.split(';').each do |o|
        d = o[1..].split(',')
        d = d.map(&:to_i) unless o[0] == 'o'
        case o[0]
        when 'b' # textured block
          @blocks << IsoBlock.new(d[0], d[1], d[2], d[3])
        when 'e'
          @enemies << Enemy.new(d[0], d[1], d[2], d[3], method(:on_enemy_encounter))
        when 'i'
          @items << Item.new(d[0], d[1], d[2], d[3], method(:on_item_picked_up))
        when 'n'
          @npcs << Npc.new(d[0], d[1], d[2], d[3])
        when 'o'
          obj_class = OBJECT_CLASSES[d[0].to_i]
          object = obj_class.new(d[1].to_i, d[2].to_i, d[3].to_i, d[4..])
          @objects << object
          @blocks << object if object.is_a?(IsoBlock)
        when 'w' # invisible block
          @blocks << IsoBlock.new(nil, d[0], d[1], d[4] || 0, d[2], d[3], 999, d[5])
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

      fill_tiles(fill, i, j) if fill
    end
  end

  def fill_tiles(fill, i, j)
    while j < M_S - 1 || j == M_S - 1 && i < M_S / 2 + 1
      @tiles[i][j] = fill.to_i
      i, j = next_tile(i, j)
    end
  end

  def init_player(entrance_index)
    entrance = @entrances[entrance_index]
    @man = Character.new(entrance[0], entrance[1], entrance[2])
    @man.on_exit = method(:on_player_leave)
  end

  def init_transition
    @fading = :in
    @overlay_alpha = 255
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
