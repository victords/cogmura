require_relative '../iso_game_object'
require_relative '../constants'

class Door < IsoGameObject
  TYPE_MAP = [
    [-28, -112],
    [-79, -128, true],
    [-28, -120, true],
  ].freeze

  attr_reader :dest_scr, :dest_entr

  def initialize(type, dest_scr, dest_entr, col, row, layer, on_open)
    img_gap_x, img_gap_y, angled = TYPE_MAP[type - 1]
    super(col, row, layer, Physics::UNIT, Physics::UNIT, "obj_door#{type}", Vector.new(img_gap_x, img_gap_y), 4, 1)
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    @on_open = on_open
    return if angled

    @sub_img = @img.map { |img| img.subimage(0, 0, img.width / 2, img.height) }
  end

  def collide?
    false
  end

  def update(man)
    if @opening
      animate_once([1, 2, 3], 7)
    elsif man.bounds.intersect?(bounds)
      @can_open = true
      if KB.key_pressed?(Gosu::KB_Z)
        @on_open.call(self)
        @opening = true
      end
    else
      @can_open = false
    end
  end

  def draw(map)
    prev_z_index = @z_index
    super(map, @z_index - (@sub_img ? 200 : 100))
    @z_index = prev_z_index

    if @can_open && !@opening
      Res.img(:fx_alert).draw(@screen_x + @img[0].width / 2 - 8, @screen_y - 28, Graphics::UI_Z_INDEX)
    end

    return unless @sub_img

    @sub_img[@img_index].draw(@screen_x, @screen_y, @z_index - 100)
  end
end
