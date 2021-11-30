require_relative '../iso_game_object'
require_relative '../constants'

class Box < IsoGameObject
  def initialize(col, row, layer)
    super(col, row, layer, 28, 28, :obj_box, Vector.new(-6, -24), 2, 1)
  end

  def collide?
    true
  end

  def update(man)
    # todo
  end
end
