Vector = MiniGL::Vector

module Graphics
  SCR_W = 1920
  SCR_H = 1080
  MAP_SIZE = 30
  TILE_WIDTH = 128
  TILE_HEIGHT = 64
  V_OFFSET = (SCR_H - MAP_SIZE * TILE_HEIGHT / 2) / 2
  UI_Z_INDEX = 10000
  FONT_LINE_SPACING = 8
end

module Physics
  UNIT = 40
  V_UNIT = 32
end

ENEMY_TYPE_MAP = [
  [:bruk, 20, -26, -32, 1, 5, 2]
].freeze
