require 'minigl'
require 'gosu'
require_relative 'constants'
require_relative 'game'
require_relative 'character'

include MiniGL

class EditorScreen < Screen
  attr_reader :map

  def initialize(id = nil, tileset = '1')
    init_props
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
end

class Editor < GameWindow
  T_W = Graphics::TILE_WIDTH
  T_H = Graphics::TILE_HEIGHT
  UI_Z = Graphics::UI_Z_INDEX
  TRANSLUCENT_RED = 0x80ff0000
  TRANSLUCENT_YELLOW = 0x80ffff00

  TILES_PER_TILESET = 14

  def initialize
    super(Graphics::SCR_W, Graphics::SCR_H, true)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-3].join('/') + '/data'
    Game.init
    @screen = EditorScreen.new

    @tilesets = Dir["#{Res.prefix}tileset/*"].sort.map { |s| s.split('/').last.chomp('.png') }
    @tileset_index = 0

    @font = Gosu::Font.new(24, name: 'DejaVu Sans')
    @panels = [
      Panel.new(10, 10, 2 * T_W + 20, 7 * T_H + 80, [
        Button.new(x: -30, y: 10, font: @font, text: '<', img: :ui_button, anchor: :bottom),
        Button.new(x: 30, y: 10, font: @font, text: '>', img: :ui_button, anchor: :bottom),
      ], :ui_panel, :tiled)
    ]
    @panel_index = 0
    @panel_alpha = 153

    @action = [:tile, 0]
  end

  def update
    KB.update
    Mouse.update
    @mouse_map_pos = @screen.map.get_map_pos(Mouse.x, Mouse.y)

    ml_press = Mouse.button_pressed?(:left)
    ml_down = Mouse.button_down?(:left)

    over_panel = @panels.find { |p| Mouse.over?(p.x, p.y, p.w, p.h) }
    if over_panel
      over_panel.update
      if @panel_index == 0 && ml_press
        tile_index = (0...TILES_PER_TILESET).find do |i|
          Mouse.over?(@panels[0].x + 10 + (i % 2) * T_W, @panels[0].y + 10 + (i / 2) * T_H, T_W, T_H)
        end
        @action = [:tile, tile_index] if tile_index
      end
    elsif @action[0] == :tile && ml_down
      @screen.set_tile(@action[1], @mouse_map_pos.x, @mouse_map_pos.y)
    end
    @panel_alpha = over_panel ? 255 : 153

    close if KB.key_pressed?(Gosu::KB_ESCAPE)
  end

  def draw
    @screen.draw
    mouse_tile_pos = @screen.map.get_screen_pos(@mouse_map_pos.x, @mouse_map_pos.y)
    G.window.draw_quad(mouse_tile_pos.x + T_W / 2, mouse_tile_pos.y, TRANSLUCENT_RED,
                       mouse_tile_pos.x + T_W, mouse_tile_pos.y + T_H / 2, TRANSLUCENT_RED,
                       mouse_tile_pos.x + T_W / 2, mouse_tile_pos.y + T_H, TRANSLUCENT_RED,
                       mouse_tile_pos.x, mouse_tile_pos.y + T_H / 2, TRANSLUCENT_RED, Graphics::UI_Z_INDEX)

    G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)
    G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)

    @panels[@panel_index].draw(@panel_alpha, UI_Z)
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
  end
end

Editor.new.show
