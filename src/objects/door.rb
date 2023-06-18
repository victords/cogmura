require_relative '../iso_game_object'
require_relative '../constants'

class Door < IsoGameObject
  attr_reader :dest_scr, :dest_entr
  attr_writer :on_open

  # type 0: along iso y-axis
  # type 1: along iso x-axis
  # type 2: angled (facing front)
  def initialize(type, dest_scr, dest_entr, col, row, layer)
    layer ||= 0
    super(col, row, layer, Physics::UNIT, Physics::UNIT, type == 2 ? :obj_door1a : :obj_door1, Vector.new(-28, type == 2 ? -48 : -112), 5, 1)
    @type = type
    @flip = type == 1
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    @z_index = col.floor + row.floor + 1

    if type != 2
      @sub_img = @img.map { |img| img.subimage(0, 0, img.width / 2, img.height) }
    end
  end

  def collide?
    false
  end

  def update(man)
    if @opening
      animate_once([1, 2, 3, 4], 7)
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
    super(map, @z_index)

    if @can_open && !@opening
      Res.img(:fx_alert).draw(@screen_x + @img[0].width / 2 * Graphics::SCALE - 4, @screen_y - 28,
                              @z_index + 1, Graphics::SCALE, Graphics::SCALE)
    end

    return unless @sub_img

    x_offset = @type == 0 ? 0 : @img[0].width * Graphics::SCALE
    @sub_img[@img_index].draw(@screen_x + x_offset, @screen_y, @z_index + 1,
                              Graphics::SCALE * (@type == 0 ? 1 : -1), Graphics::SCALE)
  end
end
