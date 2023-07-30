require_relative 'iso_game_object'

include MiniGL

class Npc < IsoGameObject
  ID_MAP = [
    [:cogjian, -38, -128]
  ].freeze
  RANGE = Physics::UNIT

  attr_reader :man_in_range

  def initialize(id, col, row, layer)
    data = ID_MAP[id]
    super(col, row, layer, 20, 20, "char_#{data[0]}", Vector.new(data[1], data[2]), 5, 1, 3)
    @balloon = Res.img(:fx_balloon)

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

  def check_next_text
    @text_index += 1 if @texts[@text_index + 1]&.[](0) == '>'
  end

  def set_angle(man)
    angle = Math.atan2(man.y + man.h / 2 - @y - @h / 2, man.x + man.w / 2 - @x - @w / 2)
    angle = 180 * angle / Math::PI
    if angle >= -22.5 && angle < 22.5
      @img_index = 3; @flip = true
    elsif angle >= 22.5 && angle < 67.5
      @img_index = 0; @flip = false
    elsif angle >= 67.5 && angle < 112.5
      @img_index = 3; @flip = false
    elsif angle >= 112.5 && angle < 157.5
      @img_index = 2; @flip = false
    elsif angle >= 157.5 || angle < -157.5
      @img_index = 4; @flip = false
    elsif angle >= -157.5 && angle < -112.5
      @img_index = 1; @flip = false
    elsif angle >= -112.5 && angle < -67.5
      @img_index = 4; @flip = true
    else
      @img_index = 2; @flip = true
    end
  end

  def update(man)
    @man_in_range = man&.grounded && @z == man.z && in_range?(man, RANGE)

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
        set_angle(man)
      end
    end
  end

  def draw(map)
    super

    pos = map.get_screen_pos((@x + @w / 2) / Physics::UNIT, (@y + @h / 2) / Physics::UNIT)
    if @talking
      y = pos.y - @height * Physics::V_UNIT >= Graphics::SCR_H / 2 ? 10 : Graphics::SCR_H - Graphics::V_OFFSET - 90
      G.window.draw_rect(10, y, Graphics::SCR_W - 20, 80, 0xccffffff, Graphics::UI_Z_INDEX)
      Game.text_helper.write_breaking(@texts[@text_index][1], 20, y + 5, Graphics::SCR_W - 40, :justified, 0, 255, Graphics::UI_Z_INDEX)
    elsif @man_in_range
      @balloon.draw(@screen_x + @img[0].width / 2 - 28, @screen_y - 58, Graphics::UI_Z_INDEX)
    end
  end
end
