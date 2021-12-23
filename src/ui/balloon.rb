require 'minigl'
require_relative '../constants'
require_relative '../game'

include MiniGL

class Balloon < Component
  attr_writer :text

  def initialize(x, y, text, type = :left, scale_x = Graphics::SCALE, scale_y = Graphics::SCALE, anchor = nil)
    super(x, y, Game.font, text, 0, 0)
    @image = Res.imgs("ui_balloon#{type.to_s.capitalize}", 2, 1)
    @scale_x = scale_x
    @scale_y = scale_y
    @anchor = anchor
    @anchor_offset_x = x
    @anchor_offset_y = y
  end

  def draw(alpha, z_index = Graphics::UI_Z_INDEX, color = 0xffffff)
    c1 = ((alpha * 0.5).to_i << 24) | color
    c2 = (alpha << 24) | @text_color
    text_width = @scale_x * @font.text_width(@text)
    @image[0].draw(@x, @y, z_index, @scale_x, @scale_y, c1)
    G.window.draw_rect(@x + 5 * @scale_x, @y, text_width, 15 * @scale_y, c1, z_index)
    @image[1].draw(@x + 5 * @scale_x + text_width, @y, z_index, @scale_x, @scale_y, c1)
    @font.draw_text(@text, @x + 5 * @scale_x, @y + 2 * @scale_y, z_index, @scale_x, @scale_y, c2)
  end
end
