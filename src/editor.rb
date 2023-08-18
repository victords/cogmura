require 'minigl'
require 'gosu'
require_relative 'constants'
require_relative 'game'
require_relative 'character'

include MiniGL

class EditorScreen < Screen
  TRANSLUCENT_RED = 0x80ff0000

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

  def draw
    super
    map_pos = @map.get_map_pos(Mouse.x, Mouse.y)
    pos = @map.get_screen_pos(map_pos.x, map_pos.y)
    G.window.draw_quad(pos.x + T_W / 2, pos.y, TRANSLUCENT_RED,
                       pos.x + T_W, pos.y + T_H / 2, TRANSLUCENT_RED,
                       pos.x + T_W / 2, pos.y + T_H, TRANSLUCENT_RED,
                       pos.x, pos.y + T_H / 2, TRANSLUCENT_RED, Graphics::UI_Z_INDEX)
  end
end

class Editor < GameWindow
  T_W = Graphics::TILE_WIDTH
  T_H = Graphics::TILE_HEIGHT
  UI_Z = Graphics::UI_Z_INDEX

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
  end

  def update
    KB.update
    Mouse.update

    @panels[@panel_index].update

    close if KB.key_pressed?(Gosu::KB_ESCAPE)
  end

  def draw
    @screen.draw
    G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)
    G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, UI_Z)

    @panels[@panel_index].draw(153, UI_Z)
    Res.tileset(@tilesets[@tileset_index], T_W, T_H).each_with_index do |tile, i|
      tile.draw(@panels[0].x + 10 + (i % 2) * T_W, @panels[0].y + 10 + (i / 2) * T_H, UI_Z)
    end
  end
end

Editor.new.show
