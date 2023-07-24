class Hud
  include MiniGL

  def initialize
    scale = Graphics::SCALE
    stats = Game.player_stats
    @panel = Panel.new(0, 20, 600, 90, [
      PanelImage.new(20, 0, :icon_hp, 0.5 * scale, 0.5 * scale, :left),
      Label.new(340, 0, Game.font, "#{stats.hp}/#{stats.max_hp}", 0, 0, 0.5 * scale, 0.5 * scale, :right),
      PanelImage.new(340, 0, :icon_mp, 0.5 * scale, 0.5 * scale, :left),
      Label.new(20, 0, Game.font, "#{stats.mp}/#{stats.max_mp}", 0, 0, 0.5 * scale, 0.5 * scale, :right),
    ], :ui_panel, :tiled, false, scale, scale, :top)
    @alpha = 255
    show
  end

  def show
    @timer = 60
  end

  def hide
    @alpha = @timer = 0
  end

  def update
    show if KB.key_pressed?(Gosu::KB_TAB)

    if @timer > 0
      if @alpha == 255
        @timer -= 1
      else
        @alpha += 17
        @alpha = 255 if @alpha > 255
      end
    elsif @alpha > 0
      @alpha -= 3
      @alpha = 0 if @alpha < 0
    end
  end

  def draw
    @panel.draw(@alpha, Graphics::UI_Z_INDEX)
  end
end
