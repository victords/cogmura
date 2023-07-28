class Message
  include MiniGL

  def initialize
    @arrow = Res.imgs(:ui_arrow, 2, 2)[1]
  end

  def visible?
    !@text.nil?
  end

  def show(type, text_id, options, on_select = nil, *msg_args)
    @bg = Res.img("ui_#{type}")
    @text = Game.text(:ui, text_id, *msg_args)
    @options = options
    @on_select = on_select
    @index = 0
  end

  def update
    return unless visible?

    if KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_Z)
      @bg = @text = nil
      @on_select&.call(@options[@index])
    elsif KB.key_pressed?(Gosu::KB_UP) && @index > 0
      @index -= 1
    elsif KB.key_pressed?(Gosu::KB_DOWN) && @index < @options.size - 1
      @index += 1
    end
  end

  def draw
    return unless visible?

    G.window.draw_rect(0, 0, Graphics::SCR_W, Graphics::SCR_H, 0x80000000, Graphics::UI_Z_INDEX)
    x = (Graphics::SCR_W - @bg.width) / 2
    y = (Graphics::SCR_H - @bg.height) / 2
    @bg.draw(x, y, Graphics::UI_Z_INDEX)
    Game.text_helper.write_breaking(@text, x + 50, y + 50, @bg.width - 100, :left, 0, 255, Graphics::UI_Z_INDEX)

    @options.each_with_index do |option, i|
      Game.text_helper.write_line(Game.text(:ui, option), x + @arrow.width + 10, y + @bg.height + 10 + i * 50, :left, 0xffffff, 255, :border, 0, 2, 255, Graphics::UI_Z_INDEX)
      @arrow.draw(x, y + @bg.height + 8 + i * 50, Graphics::UI_Z_INDEX) if i == @index
    end
  end
end
