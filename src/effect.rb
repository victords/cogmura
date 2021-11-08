require_relative 'game'

include MiniGL

class ScreenEffect
  attr_reader :destroyed

  def initialize(lifetime, &on_destroyed)
    @lifetime = lifetime
    @on_destroyed = on_destroyed
  end

  def update
    @lifetime -= 1
    return if @lifetime > 0

    @on_destroyed&.call
    @destroyed = true
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
  def initialize(item)
    super(:item_pick_up)
    article = %w(a e i o u).any? { |v| item.name.downcase.start_with?(v) } ? 'an' : 'a'
    @text = @text.sub('$', article).sub('$', item.name)
    @width = Game.font.text_width(@text) * Graphics::SCALE + 40
  end
end

class BattleSplash < ScreenEffect
  def initialize(&on_destroyed)
    super(180, &on_destroyed)
    @scale = 0
    @angle = 0
    @img = Res.img(:fx_splash)
  end
  
  def update
    super
    
    @scale += 0.03333 if @scale < Graphics::SCALE
    @angle += @lifetime >= 120 ? 6 : 1
  end
  
  def draw
    x = Graphics::SCR_W / 2
    y = Graphics::SCR_H / 2
    z = Graphics::UI_Z_INDEX
    @img.draw_rot(x, y, z, @angle, 0.5, 0.5, @scale, @scale, 0xffffffff)
    Game.text_helper.write_breaking(Game.text(:ui, :battle_start),x, y - (@scale / Graphics::SCALE) * 46,
                                    Graphics::SCR_W, :center, 0, 255, z, 2 * @scale, 2 * @scale)
  end
end

class StatChangeEffect < ScreenEffect
  def initialize(stat, delta, x, y)
    super(120)
    @icon = Res.img("icon_#{stat}")
    @text = delta < 0 ? delta.to_s : "+#{delta}"
    @color = case stat
             when :hp
               delta < 0 ? 0xff0000 : 0xff9999
             end
    @x = x + Game.font.text_width(@text) - @icon.width - 2
    @y = y - Game.font.height * 2 - 10
  end

  def draw
    Game.text_helper.write_line(@text, @x, @y, :right, @color, 255, :border, 0, 2, 255, Graphics::UI_Z_INDEX)
    @icon.draw(@x + 4, @y, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)
  end
end
