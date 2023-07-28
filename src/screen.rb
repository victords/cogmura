require_relative 'iso_block'
require_relative 'npc'
require_relative 'item'
require_relative 'enemy'
require_relative 'character'
require_relative 'effect'
require_relative 'battle/battle'
require_relative 'objects/arc'
require_relative 'objects/bed'
require_relative 'objects/box'
require_relative 'objects/door'
require_relative 'objects/graphic'
require_relative 'objects/letter'
require_relative 'ui/hud'
require_relative 'ui/menu'
require_relative 'ui/message'

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
    @map = Map.new(t_w, t_h, M_S, M_S, M_S * t_w, M_S * t_h, true)
    @map.set_camera(M_S / 4.0 * t_w, M_S / 4.0 * t_h)

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

    File.open("#{Res.prefix}map/#{id}") do |f|
      info, entrances, exits, spawn_points, objects, tiles = f.read.split('#')
      info = info.split(',')
      @tileset = Res.tileset(info[0], t_w / Graphics::SCALE, t_h / Graphics::SCALE)
      fill = info[1]

      @entrances = entrances.split(';').map { |e| e.split(',').map(&:to_f) }
      @exits = exits.split(';').map do |e|
        d = e.split(',')
        Exit.new(d[0].to_i, d[1].to_i, d[2].to_f, d[3].to_f, d[4].to_i)
      end
      @spawn_points = spawn_points.split(';').map { |p| p.split(',').map(&:to_i) }

      objects.split(';').each do |o|
        d = o[1..].split(',')
        d = d.map(&:to_i) unless o[0] == 'd' || o[0] == 'x'
        case o[0]
        when 'a'
          @objects << Arc.new(d[0], d[1], d[2], d[3], self)
        when 'b' # textured block
          @blocks << IsoBlock.new(d[0], d[1], d[2], d[3])
        when 'd'
          @objects << Door.new(d[0].to_i, d[1].to_i, d[2].to_i, d[3].to_f, d[4].to_f, d[5].to_i, method(:on_player_leave))
        when 'e'
          @enemies << Enemy.new(d[0], d[1], d[2], d[3], method(:on_enemy_encounter))
        when 'g'
          @objects << Graphic.new(@map, d[0], d[1], d[2], d[3])
        when 'i'
          @items << Item.new(d[0], d[1], d[2], d[3], method(:on_item_picked_up))
        when 'l'
          @objects << Letter.new(@map, d[0], d[1], d[2], d[3], method(:on_message_read))
        when 'n'
          @npcs << Npc.new(d[0], d[1], d[2], d[3])
        when 'w' # invisible block
          @blocks << IsoBlock.new(nil, d[0], d[1], 0, d[2], d[3])
        when 'x'
          @objects << Box.new(d[0].to_i, d[1].to_i, d[2].to_i, d[3], self)
        when '['
          bed = Bed.new(d[0], d[1], d[2], d[3], method(:on_sleep_confirm))
          @objects << bed
          @blocks << bed
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
    @hud = Hud.new
    @menu = Menu.new(@hud)
    @message = Message.new
    @end_frame_callbacks = []

    # TODO remove later
    # @grid = Res.img(:grid)
  end

  def on_player_leave(exit_obj)
    @fading = :out
    @on_fade_end = lambda do
      @on_exit.call(exit_obj)
    end
  end

  def on_item_picked_up(item_type)
    Game.player_stats.add_item(item_type)
    @effects << ItemPickUpEffect.new(item_type)
  end

  def on_money_picked_up(amount)
    Game.player_stats.money += amount
    @effects << MoneyPickUpEffect.new(amount)
  end

  def on_enemy_encounter(enemy)
    enemy.set_inactive
    @hud.hide
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
    set_message(type, text_id, [:close], method(:on_message_close))
  end

  def on_message_close(_index)
    @end_frame_callbacks << lambda do
      @man.active = true
    end
  end

  def on_sleep_confirm(price)
    set_message(:confirm, :sleep_confirm, [:yes, :no], method(:on_sleep), price)
  end

  def on_sleep(option)
    if option == :yes
      @fading = :out
      @on_fade_end = lambda do
        Game.player_stats.recover
        @man.active = true
        @fading = :in
      end
    else
      @end_frame_callbacks << lambda do
        @man.active = true
      end
    end
  end

  def add_block(col, row, layer, x_tiles, y_tiles, height)
    @blocks << IsoBlock.new(nil, col, row, layer, x_tiles, y_tiles, height)
  end

  def add_effect(effect)
    @effects << effect
  end

  def set_message(type, text_id, options, on_select, *msg_args)
    return unless @man.active

    @hud.hide
    @man.active = false
    @message.set_message(type, text_id, options, on_select, *msg_args)
  end

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

    @hud.update unless @menu.visible? || @message.visible?
    @menu.update unless @message.visible?
    @message.update
    return if @menu.visible? || @message.visible?

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

    @objects.each { |d| d.update(@man) }

    @end_frame_callbacks.each(&:call)
    @end_frame_callbacks.clear
  end

  def draw
    @map.foreach do |i, j, x, y|
      next unless @tiles[i][j]

      @tileset[@tiles[i][j]].draw(x, y + Graphics::V_OFFSET, 0, Graphics::SCALE, Graphics::SCALE)
      @grid.draw(x, y + Graphics::V_OFFSET, 0, Graphics::SCALE, Graphics::SCALE) if @grid
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

    G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)
    G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)
    @hud.draw
    @menu.draw
    @message.draw
    return unless @overlay_alpha > 0

    color = @overlay_alpha.round << 24
    G.window.draw_rect(0, 0, G.window.width, G.window.height, color, Graphics::UI_Z_INDEX)
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
