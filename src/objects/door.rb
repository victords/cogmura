require_relative 'iso_game_object_with_args'
require_relative '../constants'

class Door < IsoGameObjectWithArgs
  TYPE_MAP = [
    [-28, -112],
    [-79, -128, true],
    [-28, -120, true],
  ].freeze

  attr_reader :dest_scr, :dest_entr

  def initialize(col, row, layer, args)
    type, dest_scr, dest_entr = args.map(&:to_i)
    type ||= 1
    img_gap_x, img_gap_y, angled = TYPE_MAP[type - 1]
    super(col + 0.5, row + 0.5, layer, args, Physics::UNIT, Physics::UNIT, "obj_door#{type}", Vector.new(img_gap_x, img_gap_y), 4, 1)
    @dest_scr = dest_scr
    @dest_entr = dest_entr
    return if angled

    @sub_img = @img.map { |img| img.subimage(0, 0, img.width / 2, img.height) }
  end

  def collide?
    false
  end

  def move_to(col, row, layer)
    super(col + 0.5, row + 0.5, layer)
  end

  def update(man, screen)
    if @opening
      animate_once([1, 2, 3], 7)
    elsif man.bounds.intersect?(bounds)
      @can_open = true
      if KB.key_pressed?(Gosu::KB_Z)
        screen.on_player_leave(self)
        @opening = true
      end
    else
      @can_open = false
    end
  end

  def draw(map, z_index = nil, alpha = 255)
    @z_index = z_index if z_index
    prev_z_index = @z_index
    super(map, @z_index - (@sub_img ? 200 : 100), alpha)
    @z_index = prev_z_index

    if @can_open && !@opening
      Res.img(:fx_alert).draw(@screen_x + @img[0].width / 2 - 8, @screen_y - 28, Graphics::UI_Z_INDEX)
    end

    return unless @sub_img

    color = (alpha << 24) | 0xffffff
    @sub_img[@img_index].draw(@screen_x, @screen_y, @z_index - 100, 1, 1, color)
  end
end
