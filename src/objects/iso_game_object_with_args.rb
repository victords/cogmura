require_relative '../iso_game_object'

class IsoGameObjectWithArgs < IsoGameObject
  attr_reader :args

  def initialize(col, row, layer, args, w, h, img, img_gap, sprite_cols, sprite_rows, height = 1)
    super(col, row, layer, w, h, img, img_gap, sprite_cols, sprite_rows, height)
    @args = args || []
  end
end
