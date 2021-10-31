require_relative 'game'

include MiniGL

class ScreenEffect
  attr_reader :destroyed

  def initialize(lifetime)
    @lifetime = lifetime
  end

  def update
    @lifetime -= 1
    @destroyed = true if @lifetime <= 0
  end
end

class TextEffect < ScreenEffect
  def initialize(text_id)
    super(120)
    @text = Game.text(:ui, text_id)
    @width = Game.font.text_width(@text) * Graphics::SCALE + 40
  end

  def draw
    G.window.draw_rect((Graphics::SCR_W - @width) / 2, Graphics::SCR_H / 2 - 20, @width, 40, 0x80ffffff, Graphics::UI_Z_INDEX)
    Game.text_helper.write_line(@text, Graphics::SCR_W / 2, Graphics::SCR_H / 2 - 11, :center, 0, 255, nil, 0, 0, 0, Graphics::UI_Z_INDEX)
  end
end

class ItemPickUpEffect < TextEffect
  attr_reader :destroyed

  def initialize(item)
    super(:item_pick_up)
    article = %w(a e i o u).any? { |v| item.type.to_s.start_with?(v) } ? 'an' : 'a'
    @text = @text.sub('$', article).sub('$', item.name)
    @width = Game.font.text_width(@text) * Graphics::SCALE + 40
  end
end
