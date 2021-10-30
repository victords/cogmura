Vector = MiniGL::Vector

module Graphics
  SCALE = 2
  MAP_SIZE = 32
  TILE_WIDTH = 64
  TILE_HEIGHT = 32
  SCR_W = MAP_SIZE * TILE_WIDTH / 2
  SCR_H = MAP_SIZE * TILE_HEIGHT / 2
  UI_Z_INDEX = 10000
end

module Physics
  UNIT = 40
  V_UNIT = 16
end

module Enemy
  TYPE_MAP = [
    [:bruk, 20, -8, -4, 1, 5, 2]
  ].freeze
end
