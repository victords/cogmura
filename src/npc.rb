require_relative 'iso_game_object'

include MiniGL

class Npc < IsoGameObject
  ID_MAP = [
    [:cogjian, -12, -72]
  ].freeze

  attr_reader :height, :ramps
  attr_writer :man_in_range

  def initialize(id, col, row)
    super(col, row, 20, 20, ID_MAP[id][0], Vector.new(ID_MAP[id][1], ID_MAP[id][2]))
    @height = 3
    @ramps = nil
    @range = Rectangle.new(@x - Physics::UNIT, @y - Physics::UNIT, @w + 2 * Physics::UNIT, @h + 2 * Physics::UNIT)
    @balloon = Res.img(:balloon)

    @texts = Game.npc_texts[id].map { |t| t.split(' ', 2) }
    check_text_switches
    @text_index = 0 if @text_index.nil?

    Game.on_switch_activated << method(:check_text_switches)
  end

  def check_text_switches(s = nil)
    (@texts.size - 1).downto(0).each do |i|
      t = @texts[i]
      next unless t[0].to_i > 0

      if Game.switch_active?(t[0].to_i)
        @text_index = i
        break
      end
    end
  end

  def passable; false; end

  def intersect?(obj)
    bounds.intersect?(obj)
  end

  def in_range?(obj)
    @range.intersect?(obj)
  end

  def check_next_text
    @text_index += 1 if @texts[@text_index + 1]&.[](0) == '>'
  end

  def update
    if @talking && !@man_in_range
      @talking = false
      check_next_text
    end

    if KB.key_pressed?(Gosu::KB_Z)
      if @talking
        @talking = false
        check_next_text
      elsif @man_in_range
        @talking = true
      end
    end
  end

  def draw(map)
    super

    pos = map.get_screen_pos((@x + @w / 2) / Physics::UNIT, (@y + @h / 2) / Physics::UNIT)
    if @talking
      y = pos.y - @height * Physics::V_UNIT >= Graphics::SCR_H / 2 ? 10 : Graphics::SCR_H - 90
      G.window.draw_rect(10, y, Graphics::SCR_W - 20, 80, 0xccffffff, Graphics::UI_Z_INDEX)
      G.window.font.write_breaking(@texts[@text_index][1], 20, y + 5, Graphics::SCR_W - 40, :justified, 0, 255, Graphics::UI_Z_INDEX)
    elsif @man_in_range
      @balloon.draw(pos.x + Graphics::TILE_WIDTH / 2 - 14, pos.y - 2 * Physics::V_UNIT + @img_gap.y, @z_index, Graphics::SCALE, Graphics::SCALE)
    end
  end
end
