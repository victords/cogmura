Vector = MiniGL::Vector

module Graphics
  SCALE = 1
  MAP_SIZE = 30
  TILE_WIDTH = 128
  TILE_HEIGHT = 64
  SCR_W = MAP_SIZE * TILE_WIDTH / 2
  SCR_H = MAP_SIZE * TILE_HEIGHT / 2
  UI_Z_INDEX = 10000
end

module Physics
  UNIT = 40
  V_UNIT = 32
end

ENEMY_TYPE_MAP = [
  [:bruk, 20, -16, -8, 1, 5, 2]
].freeze
