class Hud
  include MiniGL

  def initialize
    scale = Graphics::SCALE
    @panel = Panel.new(0, 20, 600, 90, [
      PanelImage.new(20, 0, :icon_hp, 0.5 * scale, 0.5 * scale, :left),
      Label.new(340, 0, Game.font, hp_text, 0, 0, 0.5 * scale, 0.5 * scale, :right),
      PanelImage.new(340, 0, :icon_mp, 0.5 * scale, 0.5 * scale, :left),
      Label.new(20, 0, Game.font, mp_text, 0, 0, 0.5 * scale, 0.5 * scale, :right),
    ], :ui_panel, :tiled, false, scale, scale, :top)
    @alpha = 255
    show

    Game.player_stats.on_hp_change << lambda do |_, _|
      @panel.controls[1].text = hp_text
    end
    Game.player_stats.on_hp_change << lambda do |_, _|
      @panel.controls[3].text = mp_text
    end
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

  private

  def hp_text
    "#{Game.player_stats.hp}/#{Game.player_stats.max_hp}"
  end

  def mp_text
    "#{Game.player_stats.mp}/#{Game.player_stats.max_mp}"
  end
end
