require_relative '../iso_block'
require_relative '../constants'

class Bed < IsoBlock
  RANGE = Physics::UNIT * 0.5

  def initialize(col, row, layer, args)
    type = args[0].to_i
    super(type, col, row, layer)

    @interactive_area = Rectangle.new(@x - RANGE, @y - RANGE, @w + 2 * RANGE, @h + 2 * RANGE)
    @alert = Res.img(:fx_alert)
  end

  def collide?
    false
  end

  def drawn?
    @drawn
  end

  def update(man, screen)
    @drawn = false

    if @active && KB.key_pressed?(Gosu::KB_Z)
      screen.on_sleep_confirm(0)
      return
    end

    @active = man.bounds.intersect?(@interactive_area)
  end

  def draw(map, man)
    super
    if @active
      if @alert_screen_x.nil?
        screen_pos = map.get_screen_pos(@col, @row)
        screen_width = (@x_tiles + @y_tiles) * Graphics::TILE_WIDTH / 2
        @alert_screen_x = screen_pos.x - ((@y_tiles - 1) * Graphics::TILE_WIDTH / 2) + screen_width / 2 - @alert.width / 2
        @alert_screen_y = screen_pos.y + Graphics::TILE_HEIGHT / 2 - @z - @height - @alert.height
      end
      @alert.draw(@alert_screen_x, @alert_screen_y, Graphics::UI_Z_INDEX)
    end
    @drawn = true
  end
end
