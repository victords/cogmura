require_relative '../iso_game_object'
require_relative '../constants'
require_relative '../item'

include MiniGL

class Box < IsoGameObject
  RANGE = Physics::UNIT

  def initialize(col, row, layer, content, screen)
    super(col, row, layer, 28, 28, :obj_box, Vector.new(-26, -72), 2, 1)
    value = content[1..].to_i
    @on_open = lambda do
      case content[0]
      when 'i'
        screen.on_item_picked_up(Item::TYPE_MAP[value][0])
      when '$'
        screen.on_money_picked_up(value)
      end
    end
  end

  def collide?
    true
  end

  def update(man)
    return if @opened

    if plane_distance(man) <= RANGE
      @in_range = true
      if KB.key_pressed?(Gosu::KB_Z)
        @on_open.call
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
    Res.img(:fx_alert).draw(@screen_x + @img[0].width / 2 * Graphics::SCALE - 4, @screen_y - 28,
                            @z_index + 1, Graphics::SCALE, Graphics::SCALE)
  end
end
