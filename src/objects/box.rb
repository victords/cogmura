require_relative '../iso_game_object'
require_relative '../constants'
require_relative '../item'

include MiniGL

class Box < IsoGameObject
  RANGE = Physics::UNIT

  def initialize(col, row, layer, args)
    super(col, row, layer, 28, 28, :obj_box, Vector.new(-26, -72), 2, 1)
    @args = args
  end

  def collide?
    true
  end

  def update(man, screen)
    return if @opened

    if in_range?(man, RANGE)
      @in_range = true
      if KB.key_pressed?(Gosu::KB_Z)
        case @args[0]
        when 'i'
          screen.on_item_picked_up(Item::MAP[@args[1].to_i][0])
        when '$'
          screen.on_money_picked_up(@args[1].to_i)
        end
        @img_index = 1
        @opened = true
      end
    else
      @in_range = false
    end
  end

  def draw(map, z_index = nil, alpha = 255)
    super

    return unless @in_range && !@opened
    Res.img(:fx_alert).draw(@screen_x + 32, @screen_y - 28, Graphics::UI_Z_INDEX)
  end
end
