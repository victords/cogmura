require_relative 'iso_game_object_with_args'
require_relative '../constants'

class Bed < IsoGameObjectWithArgs
  RANGE = Physics::UNIT * 0.5

  def initialize(col, row, layer, args)
    unit = Physics::UNIT
    super(col, row, layer, args, unit, unit, :block_bed1, nil, 1, 1)

    @x_tiles = args[0]&.to_i || 1
    @y_tiles = args[1]&.to_i || 1
    @interactive_area = Rectangle.new(@x - RANGE, @y - RANGE, @x_tiles * unit + 2 * RANGE, @y_tiles * unit + 2 * RANGE)
    @alert = Res.img(:fx_alert)
  end

  def collide?
    false
  end

  def update(man, screen)
    if @active && KB.key_pressed?(Gosu::KB_Z)
      screen.on_sleep_confirm(0)
      return
    end

    @active = man.bounds.intersect?(@interactive_area)
  end

  def draw(map, z_index = nil, alpha = nil)
    if @alert_screen_x.nil?
      screen_pos = map.get_screen_pos(col, row)
      screen_width = (@x_tiles + @y_tiles) * Graphics::TILE_WIDTH / 2
      @alert_screen_x = screen_pos.x - ((@y_tiles - 1) * Graphics::TILE_WIDTH / 2) + screen_width / 2 - @alert.width / 2
      @alert_screen_y = screen_pos.y + Graphics::TILE_HEIGHT / 2 - @z - @height - @alert.height
      if Game.editor
        @screen_x = screen_pos.x
        @screen_y = screen_pos.y
      end
    end

    Game.font.draw_text("B#{@x_tiles},#{@y_tiles}", @screen_x, @screen_y, Graphics::UI_Z_INDEX, 0.5, 0.5, 0xff000000) if Game.editor
    return unless @active

    @alert.draw(@alert_screen_x, @alert_screen_y, Graphics::UI_Z_INDEX)
  end
end
