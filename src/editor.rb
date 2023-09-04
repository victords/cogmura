require 'minigl'
require 'gosu'
require_relative 'constants'
require_relative 'game'
require_relative 'ui/panel_image'

include MiniGL

class InvisibleWall < IsoBlock
  OUTLINE = 0xff000000
  FILL = 0x66ffffff

  attr_writer :x_tiles, :y_tiles
  attr_accessor :angled

  def initialize(col, row, layer, x_tiles, y_tiles, angled)
    super(nil, col, row, layer, x_tiles, y_tiles, 999, angled)
    @angled = angled
  end

  def draw(map, man, z_index = nil, alpha = nil)
    @z_index = z_index if z_index
    pos = map.get_screen_pos(@col, @row)
    if @ramps
      x1 = pos.x
      x2 = x1 + @x_tiles * Graphics::TILE_WIDTH
      y1 = pos.y + Graphics::TILE_HEIGHT / 2 - @z
      y2 = y1 + @y_tiles * Graphics::TILE_HEIGHT
      G.window.draw_rect(x1, 0, x2 - x1, y2, FILL, @z_index)
      G.window.draw_rect(x1, y1, x2 - x1, y2 - y1, FILL, @z_index)
      G.window.draw_line(x1, 0, OUTLINE, x1, y2, OUTLINE, @z_index)
      G.window.draw_line(x2, 0, OUTLINE, x2, y2, OUTLINE, @z_index)
      G.window.draw_line(x1, y1, OUTLINE, x2, y1, OUTLINE, @z_index)
      G.window.draw_line(x1, y2, OUTLINE, x2, y2, OUTLINE, @z_index)
    else
      x1 = pos.x + Graphics::TILE_WIDTH / 2
      x2 = x1 + @x_tiles * Graphics::TILE_WIDTH / 2
      x3 = x1 - @y_tiles * Graphics::TILE_WIDTH / 2
      x4 = x3 + @x_tiles * Graphics::TILE_WIDTH / 2
      y1 = pos.y - @z
      y2 = y1 + @x_tiles * Graphics::TILE_HEIGHT / 2
      y3 = y1 + @y_tiles * Graphics::TILE_HEIGHT / 2
      y4 = y3 + @x_tiles * Graphics::TILE_HEIGHT / 2
      G.window.draw_line(x1, 0, OUTLINE, x1, y1, OUTLINE, @z_index)
      G.window.draw_line(x2, 0, OUTLINE, x2, y2, OUTLINE, @z_index)
      G.window.draw_line(x3, 0, OUTLINE, x3, y3, OUTLINE, @z_index)
      G.window.draw_line(x4, 0, OUTLINE, x4, y4, OUTLINE, @z_index)
      G.window.draw_quad(x1, 0, FILL, x3, 0, FILL, x3, y3, FILL, x4, y4, FILL, @z_index)
      G.window.draw_quad(x1, 0, FILL, x2, 0, FILL, x2, y2, FILL, x4, y4, FILL, @z_index)
      G.window.draw_quad(x1, y1, FILL, x2, y2, FILL, x3, y3, FILL, x4, y4, FILL, @z_index)
    end
  end
end

class EditorEntrance
  attr_reader :col, :row

  def initialize(col, row, layer, spawn_point)
    @col = col
    @row = row
    @layer = layer
    @z = layer * Physics::V_UNIT
    @font = Gosu::Font.new(24, name: 'DejaVu Sans')
    @spawn_point = spawn_point
  end

  def move_to(col, row, layer)
    @col = col
    @row = row
    @layer = layer
    @z = layer * Physics::V_UNIT
    @pos = nil
  end

  def draw(map, index)
    @pos = map.get_screen_pos(@col, @row) + Vector.new(Graphics::TILE_WIDTH / 2, Graphics::TILE_HEIGHT / 2) if @pos.nil?
    G.window.draw_rect(@pos.x - 12, @pos.y - 12 - @z, 24, 24, @spawn_point ? 0xffffff00 : 0xff0000ff, Graphics::UI_Z_INDEX)
    @font.draw_text(index.to_s, @pos.x - 10, @pos.y - 12, Graphics::UI_Z_INDEX, 1, 1, @spawn_point ? 0xff000000 : 0xffffffff)
  end
end

class EditorExit < Exit
  def initialize(dest_scr, dest_entr, col, row, layer)
    super
    @z = layer * Physics::V_UNIT
    @font = Gosu::Font.new(24, name: 'DejaVu Sans')
  end

  def move_to(col, row, layer)
    @col = col
    @row = row
    @layer = layer
    @z = layer * Physics::V_UNIT
    @pos = nil
  end

  def draw(map)
    @pos = map.get_screen_pos(@col, @row) + Vector.new(Graphics::TILE_WIDTH / 2, Graphics::TILE_HEIGHT / 2) if @pos.nil?
    G.window.draw_rect(@pos.x - 24, @pos.y - 12 - @z, 48, 24, 0xffff0000, Graphics::UI_Z_INDEX)
    @font.draw_text("#{@dest_scr},#{@dest_entr}", @pos.x - 22, @pos.y - 12, Graphics::UI_Z_INDEX, 1, 1, 0xffffffff)
  end
end

class EditorScreen < Screen
  attr_reader :map

  def initialize(id = nil, tileset = '1')
    init_props
    @entrances = []
    @exits = []
    @spawn_points = []
    if id
      load_from_file(id)
    else
      @tileset = Res.tileset(tileset, T_W, T_H)
      fill_tiles(0, M_S / 2 - 1, 0)
    end
    @man = Character.new(0, 0, 0)
    @overlay_alpha = 0
    @grid = Res.img(:grid)
  end

  def set_tile(tile, i, j)
    @tiles[i][j] = tile
  end

  def change_fill_tile(tile)
    fill_tiles(tile, M_S / 2 - 1, 0)
  end

  def add_wall(col, row, layer, x_tiles, y_tiles, angled)
    @blocks << InvisibleWall.new(col, row, layer, x_tiles, y_tiles, angled)
  end

  def add_block(type, col, row, layer = 0)
    new_block = IsoBlock.new(type, col, row, layer)
    @blocks.delete_if { |b| b.block_intersect?(new_block) }
    @blocks << new_block
  end

  def add_item(id, col, row, layer = 0)
    item = @items.find { |i| i.col == col && i.row == row }
    if item
      return if item.key == Item::MAP[id][0]
      @items.delete(item)
    end
    @items << Item.new(id, col, row, layer, nil)
  end

  def add_npc(id, col, row, layer = 0)
    npc = @npcs.find { |n| n.col == col && n.row == row }
    if npc
      return if npc.id == id
      @npcs.delete(npc)
    end
    @npcs << Npc.new(id, col, row, layer)
  end

  def add_enemy(id, col, row, layer = 0)
    enemy = @enemies.find { |e| e.col == col && e.row == row }
    if enemy
      return if enemy.type == ENEMY_TYPE_MAP[id][0]
      @enemies.delete(enemy)
    end
    @enemies << Enemy.new(id, col, row, layer, nil)
  end

  def add_object(obj)
    @objects << obj
  end

  def add_entrance(col, row, layer, spawn_point)
    list = spawn_point ? @spawn_points : @entrances
    list << EditorEntrance.new(col, row, layer, spawn_point)
  end

  def add_exit(col, row, layer, dest_scr, dest_entr)
    @exits << EditorExit.new(dest_scr, dest_entr, col, row, layer)
  end

  def remove(col, row)
    [@blocks, @items, @npcs, @enemies, @objects, @entrances, @exits, @spawn_points].each do |list|
      obj = list.find { |o| o.col == col && o.row == row }
      if obj
        list.delete(obj)
        break
      end
    end
  end

  def draw
    super
    @entrances.each_with_index { |e, i| e.draw(@map, i) }
    @exits.each { |x| x.draw(@map) }
    @spawn_points.each_with_index { |s, i| s.draw(@map, i) }
  end
end

class Editor < GameWindow
  T_W = Graphics::TILE_WIDTH
  T_H = Graphics::TILE_HEIGHT
  UI_Z = Graphics::UI_Z_INDEX
  TRANSLUCENT_RED = 0x80ff0000
  TRANSLUCENT_YELLOW = 0x80ffff00

  TILES_PER_TILESET = 14
  PANEL_SHORTCUTS = {
    Gosu::KB_T => { index: 0, action: :tile },
    Gosu::KB_B => { index: 1, action: :block },
    Gosu::KB_I => { index: 2, action: :item },
    Gosu::KB_N => { index: 3, action: :npc },
    Gosu::KB_E => { index: 4, action: :enemy },
    Gosu::KB_W => { index: 5, action: :wall },
    Gosu::KB_O => { index: 6, action: :object },
    Gosu::KB_Z => { index: 7, action: :entrance },
    Gosu::KB_X => { index: 8, action: :exit },
  }.freeze

  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, true)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Game.init
    @screen = EditorScreen.new

    @tilesets = Dir["#{Res.prefix}tileset/*"].sort.map { |s| s.split('/').last.chomp('.png') }
    @tileset_index = 0
    @fill_tile = 0
    @layer = 0

    @blocks = IsoBlock::TYPE_MAP.map { |a| a[3].to_s }
    @items = Item::MAP.map { |a| a[0].to_s }
    @npcs = Npc::ID_MAP.map { |a| a[0].to_s }
    @enemies = ENEMY_TYPE_MAP.map { |a| a[0].to_s }
    @objects = Screen::OBJECT_CLASSES.values

    @font = Gosu::Font.new(24, name: 'DejaVu Sans')
    @panels = [
      Panel.new(10, 10, 2 * T_W + 20, 7 * T_H + 140, [
        Button.new(x: -30, y: 70, font: @font, text: '<', img: :ui_button, anchor: :bottom),
        Button.new(x: 30, y: 70, font: @font, text: '>', img: :ui_button, anchor: :bottom),
        Button.new(x: -50, y: 10, font: @font, text: '<', img: :ui_button, anchor: :bottom) { change_fill_tile(-1) },
        Button.new(x: 50, y: 10, font: @font, text: '>', img: :ui_button, anchor: :bottom) { change_fill_tile(1) },
        Label.new(x: 0, y: 23, font: @font, text: '0', img: :ui_button, anchor: :bottom),
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 70, [
        Label.new(x: 0, y: 0, font: @font, text: @blocks[0], anchor: :center),
        Button.new(x: 10, y: 0, font: @font, text: '<', img: :ui_button, anchor: :left) { change_block_selection(-1) },
        Button.new(x: 10, y: 0, font: @font, text: '>', img: :ui_button, anchor: :right) { change_block_selection(1) },
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 184, 70, [
        PanelImage.new(0, 0, "icon_#{@items[0]}", 1, 1, :center),
        Button.new(x: 10, y: 0, font: @font, text: '<', img: :ui_button, anchor: :left) { change_item_selection(-1) },
        Button.new(x: 10, y: 0, font: @font, text: '>', img: :ui_button, anchor: :right) { change_item_selection(1) },
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 70, [
        Label.new(x: 0, y: 0, font: @font, text: @npcs[0], anchor: :center),
        Button.new(x: 10, y: 0, font: @font, text: '<', img: :ui_button, anchor: :left) { change_npc_selection(-1) },
        Button.new(x: 10, y: 0, font: @font, text: '>', img: :ui_button, anchor: :right) { change_npc_selection(1) },
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 70, [
        Label.new(x: 0, y: 0, font: @font, text: @enemies[0], anchor: :center),
        Button.new(x: 10, y: 0, font: @font, text: '<', img: :ui_button, anchor: :left) { change_enemy_selection(-1) },
        Button.new(x: 10, y: 0, font: @font, text: '>', img: :ui_button, anchor: :right) { change_enemy_selection(1) },
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 170, [
        Label.new(x: 0, y: 23, font: @font, text: '1', anchor: :top),
        Button.new(x: 10, y: 10, font: @font, text: '<', img: :ui_button, anchor: :top_left) { change_wall_width(-1) },
        Button.new(x: 10, y: 10, font: @font, text: '>', img: :ui_button, anchor: :top_right) { change_wall_width(1) },
        Label.new(x: 0, y: 83, font: @font, text: '1', anchor: :top),
        Button.new(x: 10, y: 70, font: @font, text: '<', img: :ui_button, anchor: :top_left) { change_wall_height(-1) },
        Button.new(x: 10, y: 70, font: @font, text: '>', img: :ui_button, anchor: :top_right) { change_wall_height(1) },
        ToggleButton.new(x: 10, y: 10, font: @font, text: 'angled', img: :ui_checkbox, center_x: false, margin_x: 40, anchor: :bottom_left) do |checked|
          @active_object = InvisibleWall.new(0, 0, @layer, @active_object.x_tiles, @active_object.y_tiles, checked)
        end,
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 110, [
        Label.new(x: 0, y: 23, font: @font, text: @objects[0].name, anchor: :top),
        Button.new(x: 10, y: 10, font: @font, text: '<', img: :ui_button, anchor: :top_left) { change_object_selection(-1) },
        Button.new(x: 10, y: 10, font: @font, text: '>', img: :ui_button, anchor: :top_right) { change_object_selection(1) },
        TextField.new(x: 10, y: 10, font: @font, img: :ui_textField, anchor: :bottom_left, margin_x: 8, margin_y: 3) { set_active_object },
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 200, 84, [
        Label.new(x: 10, y: 10, font: @font, text: 'Entrance'),
        ToggleButton.new(x: 10, y: 10, font: @font, text: 'spawn point', img: :ui_checkbox, center_x: false, margin_x: 40, anchor: :bottom_left),
      ], :ui_panel, :tiled),
      Panel.new(10, 10, 240, 84, [
        Label.new(x: 10, y: 10, font: @font, text: 'Exit'),
        TextField.new(x: 10, y: 10, font: @font, img: :ui_textField, anchor: :bottom_left, margin_x: 8, margin_y: 3),
      ], :ui_panel, :tiled),
    ]
    @layer_panel = Panel.new(-10, -10, 150, 50, [
      Label.new(x: 20, y: 0, font: @font, text: 'Layer:', anchor: :left),
      Label.new(x: 20, y: 0, font: @font, text: @layer.to_s, anchor: :right),
    ], :ui_panel, :tiled, nil, 1, 1, :bottom_left)
    @panel_alpha = 153
    hide_panels

    @action = [:tile, 0]
  end

  def update
    KB.update
    Mouse.update
    @mouse_map_pos = @screen.map.get_map_pos(Mouse.x, Mouse.y)

    ml_press = Mouse.button_pressed?(:left)
    ml_down = Mouse.button_down?(:left)
    mr_press = Mouse.button_pressed?(:right)

    active_panel = @panel_index && @panels[@panel_index]
    over_panel = active_panel && Mouse.over?(active_panel.x, active_panel.y, active_panel.w, active_panel.h)
    if over_panel
      active_panel.update
      if @panel_index == 0 && ml_press
        tile_index = (0...TILES_PER_TILESET).find do |i|
          Mouse.over?(@panels[0].x + 10 + (i % 2) * T_W, @panels[0].y + 10 + (i / 2) * T_H, T_W, T_H)
        end
        @action = [:tile, tile_index] if tile_index
      end
    elsif @action[0] == :tile && ml_down
      @screen.set_tile(@action[1], @mouse_map_pos.x, @mouse_map_pos.y)
    elsif %i[block item npc enemy].include?(@action[0])
      if ml_press
        @screen.send("add_#{@action[0]}", @action[1], @mouse_map_pos.x, @mouse_map_pos.y, @layer)
      else
        update_active_object_position
      end
    elsif @action[0] == :wall
      if ml_press
        @screen.add_wall(@mouse_map_pos.x, @mouse_map_pos.y, @layer, @active_object.x_tiles, @active_object.y_tiles, @active_object.angled)
      else
        update_active_object_position
      end
    elsif @action[0] == :object
      if ml_press
        @screen.add_object(@objects[@action[1]].new(@mouse_map_pos.x, @mouse_map_pos.y, @layer, @panels[6].controls[3].text.split(',')))
      else
        update_active_object_position
      end
    elsif @action[0] == :entrance && ml_press
      @screen.add_entrance(@mouse_map_pos.x, @mouse_map_pos.y, @layer, @panels[7].controls[1].checked)
    elsif @action[0] == :exit && ml_press
      @screen.add_exit(@mouse_map_pos.x, @mouse_map_pos.y, @layer, *@panels[8].controls[1].text.split(',').map(&:to_i))
    end

    if mr_press && !over_panel
      @screen.remove(@mouse_map_pos.x, @mouse_map_pos.y)
    end

    @panel_alpha = over_panel ? 255 : 153

    PANEL_SHORTCUTS.each do |k, v|
      if KB.key_pressed?(k)
        toggle_panel(v[:index], v[:action])
        break
      end
    end

    if KB.key_pressed?(Gosu::KB_UP)
      change_layer(1)
    elsif KB.key_pressed?(Gosu::KB_DOWN) && @layer > 0
      change_layer(-1)
    end

    close if KB.key_pressed?(Gosu::KB_ESCAPE)
  end

  def draw
    @screen.draw
    if @active_object.is_a?(IsoBlock)
      @active_object.draw(@screen.map, nil, Graphics::UI_Z_INDEX, 127)
    else
      @active_object&.draw(@screen.map, Graphics::UI_Z_INDEX, 127)
    end

    mouse_tile_pos = @screen.map.get_screen_pos(@mouse_map_pos.x, @mouse_map_pos.y)
    G.window.draw_quad(mouse_tile_pos.x + T_W / 2, mouse_tile_pos.y, TRANSLUCENT_RED,
                       mouse_tile_pos.x + T_W, mouse_tile_pos.y + T_H / 2, TRANSLUCENT_RED,
                       mouse_tile_pos.x + T_W / 2, mouse_tile_pos.y + T_H, TRANSLUCENT_RED,
                       mouse_tile_pos.x, mouse_tile_pos.y + T_H / 2, TRANSLUCENT_RED, Graphics::UI_Z_INDEX)

    G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)
    G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)

    @panels[@panel_index].draw(@panel_alpha, UI_Z) if @panel_index
    if @panel_index == 0
      color = (@panel_alpha << 24) | 0xffffff
      Res.tileset(@tilesets[@tileset_index], T_W, T_H).each_with_index do |tile, i|
        tile.draw(@panels[0].x + 10 + (i % 2) * T_W, @panels[0].y + 10 + (i / 2) * T_H, UI_Z, 1, 1, color)
      end
      if @action[0] == :tile
        i = @action[1]
        G.window.draw_rect(@panels[0].x + 10 + (i % 2) * T_W, @panels[0].y + 10 + (i / 2) * T_H, T_W, T_H, TRANSLUCENT_YELLOW, UI_Z)
      end
    end
    @layer_panel.draw(@panel_alpha, UI_Z)
  end

  private

  def hide_panels
    @panels.each { |p| p.visible = false }
    @panel_index = nil
  end

  def toggle_panel(index, action)
    if @panel_index == index
      hide_panels
    else
      hide_panels
      @panel_index = index
      @panels[@panel_index].visible = true
      if action
        @action = [action, 0]
        set_active_object
      end
    end
  end

  def change_fill_tile(delta)
    tileset = Res.tileset(@tilesets[@tileset_index], T_W, T_H)
    @fill_tile += delta
    @fill_tile = 0 if @fill_tile >= tileset.size
    @fill_tile = tileset.size - 1 if @fill_tile < 0
    @panels[0].controls[4].text = @fill_tile.to_s
    @screen.change_fill_tile(@fill_tile)
  end

  def change_block_selection(delta)
    change_selection(@blocks, delta)
    @panels[1].controls[0].text = @blocks[@action[1]]
  end

  def change_item_selection(delta)
    change_selection(@items, delta)
    @panels[2].controls[0].image = "icon_#{@items[@action[1]]}"
  end

  def change_npc_selection(delta)
    change_selection(@npcs, delta)
    @panels[3].controls[0].text = @npcs[@action[1]]
  end

  def change_enemy_selection(delta)
    change_selection(@enemies, delta)
    @panels[4].controls[0].text = @enemies[@action[1]]
  end

  def change_object_selection(delta)
    change_selection(@objects, delta)
    @panels[6].controls[0].text = @objects[@action[1]].name
    @panels[6].controls[3].text = ''
  end

  def change_selection(list, delta)
    @action[1] += delta
    @action[1] = 0 if @action[1] >= list.size
    @action[1] = list.size - 1 if @action[1] < 0
    set_active_object
  end

  def change_wall_width(delta)
    @active_object.x_tiles += delta if delta > 0 || @active_object.x_tiles > 1
    @panels[5].controls[0].text = @active_object.x_tiles.to_s
  end

  def change_wall_height(delta)
    @active_object.y_tiles += delta if delta > 0 || @active_object.y_tiles > 1
    @panels[5].controls[3].text = @active_object.y_tiles.to_s
  end

  def set_active_object
    case @action[0]
    when :block
      @active_object = IsoBlock.new(@action[1], 0, 0)
    when :item
      @active_object = Item.new(@action[1], 0, 0, 0, nil)
    when :npc
      @active_object = Npc.new(@action[1], 0, 0, 0)
    when :enemy
      @active_object = Enemy.new(@action[1], 0, 0, 0, nil)
    when :wall
      @active_object = InvisibleWall.new(@layer, 0, 0, 1, 1, false)
    when :object
      @active_object = @objects[@action[1]].new(0, 0, @layer, @panels[6].controls[3].text.split(','))
    end
  end

  def update_active_object_position
    @active_object&.move_to(@mouse_map_pos.x, @mouse_map_pos.y, @layer)
  end

  def change_layer(delta)
    @layer += delta
    update_active_object_position
    @layer_panel.controls[1].text = @layer.to_s
  end
end

Editor.new.show
