require_relative '../iso_game_object'

class RecoveryPad < IsoGameObject
  def initialize(col, row, layer, _args)
    super(col, row, layer, 20, 20, :obj_recoveryPad, Vector.new(-54, -12), 1, 1)
    @z_index = 100 * (col + row) + 10 * layer
  end

  def update(man, screen)

  end

  def draw(map)
    super(map, @z_index)
  end

  def collide?; false; end
end
