require_relative '../iso_game_object'

class Letter < IsoGameObject
  RANGE = Physics::UNIT

  def initialize(col, row, layer, args)
    super(col + 0.25, row - 0.25, layer, 0, 0, :obj_letter, Vector.new(0, 0), 1, 1, 0)
    @img_gap.x = -@img[0].width / 2
    @img_gap.y = -@img[0].height / 2
    @text_id = "message_#{args[0]}"
  end

  def collide?
    false
  end

  def update(man, screen)
    return if @opened

    if in_range?(man, RANGE)
      @in_range = true
      if KB.key_pressed?(Gosu::KB_Z)
        screen.on_message_read(:letter, @text_id)
      end
    else
      @in_range = false
    end
  end

  def draw(map, z_index = nil, alpha = 255)
    super
    return unless @in_range && !@opened

    Res.img(:fx_alert).draw(@screen_x + @img[0].width * 0.5 - 8, @screen_y - 60, Graphics::UI_Z_INDEX)
  end
end
