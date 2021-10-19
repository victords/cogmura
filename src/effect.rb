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

class ItemPickUpEffect < ScreenEffect
  attr_reader :destroyed

  def initialize(item)
    super(120)
    article = %w(a e i o u).any? { |v| item.type.to_s.start_with?(v) } ? 'an' : 'a'
    @text = Game.text(:ui, :item_pick_up).sub('$', article).sub('$', item.name)
  end

  def draw
    G.window.draw_rect(Graphics::SCR_W / 2 - 200, Graphics::SCR_H / 2 - 20, 400, 40, 0x80ffffff, Graphics::UI_Z_INDEX)
    G.window.font.write_line(@text, Graphics::SCR_W / 2, Graphics::SCR_H / 2 - 11, :center, 0, 255, nil, 0, 0, 0, Graphics::UI_Z_INDEX)
  end
end
