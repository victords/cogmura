require_relative 'iso_game_object'
require_relative 'constants'

class Door < IsoGameObject
  attr_reader :dest_scr, :dest_entr
  attr_writer :on_open

  # type 0: along iso y-axis
  # type 1: along iso x-axis
  # type 2: angled (facing front)
  def initialize(type, dest_scr, dest_entr, i, j, z)
    super(i, j, Physics::UNIT, Physics::UNIT, type == 2 ? :door1a : :door1, Vector.new(-4, type == 2 ? -64 : -76), 5, 1)
    @type = type
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    @z = z
    @z_index = i.floor + j.floor + 1

    if type != 2
      @sub_img = @img.map { |img| img.subimage(0, 0, img.width / 2, img.height) }
    end

    @alert = Res.img(:alert)
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
    super(map, @type == 1 ? :horiz : nil, @z_index)

    if @can_open && !@opening
      @alert.draw(@screen_x + @img_gap.x + @img[0].width / 2 * Graphics::SCALE - 4, @screen_y + @img_gap.y - 28,
                  @z_index + 1, Graphics::SCALE, Graphics::SCALE)
    end

    return unless @sub_img

    x_offset = @type == 0 ? 0 : @img[0].width * Graphics::SCALE
    @sub_img[@img_index].draw(@screen_x + @img_gap.x + x_offset, @screen_y + @img_gap.y, @z_index + 1,
                              Graphics::SCALE * (@type == 0 ? 1 : -1), Graphics::SCALE)
  end
end
