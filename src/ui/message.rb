class Message
  include MiniGL

  def initialize(on_close)
    @on_close = on_close
  end

  def visible?
    !@text.nil?
  end

  def set_message(type, text)
    @bg = Res.img("ui_#{type}")
    @text = text
  end

  def update
    return unless visible?
    return unless KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_Z)

    @bg = @text = nil
    @on_close.call
  end

  def draw
    return unless visible?

    G.window.draw_rect(0, 0, Graphics::SCR_W, Graphics::SCR_H, 0x80000000, Graphics::UI_Z_INDEX)
    x = (Graphics::SCR_W - @bg.width) / 2
    y = (Graphics::SCR_H - @bg.height) / 2
    @bg.draw(x, y, Graphics::UI_Z_INDEX)
    Game.text_helper.write_breaking(@text, x + 50, y + 50, @bg.width - 100, :left, 0, 255, Graphics::UI_Z_INDEX)
  end
end
