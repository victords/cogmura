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
  def initialize(text_id, *args)
    super(120)
    @text = Game.text(:ui, text_id, *args)
    @width = Game.font.text_width(@text) * 0.5 * Graphics::SCALE + 40
    @height = Game.font.height * 0.5 + 10
    @x = (Graphics::SCR_W - @width) / 2
    @y = (Graphics::SCR_H - @height) / 2
  end

  def draw
    G.window.draw_rect(@x, @y, @width, @height, 0x80ffffff, Graphics::UI_Z_INDEX)
    Game.text_helper.write_line(@text, @x + 20, @y + 5, :left, 0, 255, nil, 0, 0, 0, Graphics::UI_Z_INDEX)
  end
end

class ItemPickUpEffect < TextEffect
  def initialize(item_type)
    name = Game.text(:ui, "item_#{item_type}")
    article = %w(a e i o u).any? { |v| name.downcase.start_with?(v) } ? 'an' : 'a'
    super(:item_pick_up, article, name)
  end
end

class MoneyPickUpEffect < TextEffect
  def initialize(amount)
    super(:money_pick_up, amount)
  end
end

class BattleSplash < ScreenEffect
  def initialize(&on_destroyed)
    super(150, &on_destroyed)
    @scale = 0
    @angle = 0
    @img = Res.img(:fx_splash)
  end

  def update
    super

    @scale += 0.02 if @scale < Graphics::SCALE
    @angle += @lifetime >= 90 ? 5 : 1
  end

  def draw
    x = Graphics::SCR_W / 2
    y = Graphics::SCR_H / 2
    z = Graphics::UI_Z_INDEX
    @img.draw_rot(x, y, z, @angle, 0.5, 0.5, @scale, @scale, 0xffffffff)
    Game.text_helper.write_breaking(
      Game.text(:ui, :battle_start), x, y - (@scale / Graphics::SCALE) * (Game.font.height + Graphics::FONT_LINE_SPACING / 2),
      Graphics::SCR_W, :center, 0, 255, z, @scale * Graphics::SCALE, @scale * Graphics::SCALE
    )
  end
end

class BattleVictory < ScreenEffect
  def initialize(&on_destroyed)
    super(120, &on_destroyed)
    @scale = 0
  end

  def update
    super
    @scale += 0.1 if @scale < Graphics::SCALE
  end

  def draw
    Game.text_helper.write_line(Game.text(:ui, :battle_won), Graphics::SCR_W / 2,
                                Graphics::SCR_H / 2 - (@scale / Graphics::SCALE) * Game.font.height,
                                :center, 0xffffff, 255, :border, 0, 2 * @scale, 255, Graphics::UI_Z_INDEX, @scale, @scale)
  end
end

class StatChangeEffect < ScreenEffect
  SPACING = 8

  def initialize(stat, delta, x, y)
    super(120)
    @icon = Res.img("icon_#{stat}")
    @text = delta < 0 ? delta.to_s : "+#{delta}"
    @color = case stat
             when :hp
               delta < 0 ? 0xff0000 : 0xff9999
             end
    width = Game.font.text_width(@text) * 0.5 + @icon.width + SPACING
    @x = x + width / 2 - @icon.width
    @y = y - Game.font.height * 0.5 - 10
  end

  def draw
    Game.text_helper.write_line(@text, @x - SPACING, @y, :right, @color, 255, :border, 0, 2, 255, Graphics::UI_Z_INDEX)
    @icon.draw(@x, @y, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)
  end
end

class RecoverEffect < ScreenEffect
  def initialize(x, y)
    super(155)
    @x = x
    @y = y
    @hp = Res.img(:icon_hp)
    @mp = Res.img(:icon_mp)
    @effects = []
    @timer = 0
  end

  def update
    super
    @timer += 1
    if @timer == 5 && @lifetime >= 35
      y_offset = ((155 - @lifetime).to_f / 155 * 30).round
      @effects << Effect.new(@x - 4 + rand(37), @y - 4 - y_offset + rand(37), :fx_glow, 3, 1, 7, [0, 1, 2, 1, 0])
      @timer = 0
    end
    @effects.reverse_each do |e|
      e.update
      @effects.delete(e) if e.dead
    end
  end

  def draw
    color = @lifetime >= 35 ? 0xffffffff : ((@lifetime.to_f / 35 * 255).round << 24) | 0xffffff
    y_offset = ((155 - @lifetime).to_f / 155 * 30).round
    @hp.draw(@x, @y - 10 - y_offset, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE, color)
    @mp.draw(@x + 20, @y - y_offset, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE, color)
    @effects.each { |e| e.draw(nil, Graphics::SCALE, Graphics::SCALE, 255, 0xffffff, nil, Graphics::UI_Z_INDEX) }
  end
end
