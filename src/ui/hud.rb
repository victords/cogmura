require 'minigl'
require_relative 'panel_image'
require_relative '../constants'

class Hud
  include MiniGL

  def initialize
    scale = Graphics::SCALE
    @stats = Game.player_stats
    @labels = {}
    @panel = Panel.new(
      10, 10, Graphics::SCR_W - 20, Graphics::SCR_H - 20,
      [
        Label.new(0, 10, Game.font, "- #{Game.text(:ui, :stats)} -", 0, 0, 2 * scale, 2 * scale, :top),
        PanelImage.new(50, 100, :icon_hp, 2 * scale, 2 * scale),
        (@labels[:hp] = Label.new(114, 100, Game.font, "#{@stats.hp}/#{@stats.max_hp}", 0, 0, 2 * scale, 2 * scale)),
        PanelImage.new(50, 200, :icon_mp, 2 * scale, 2 * scale),
        (@labels[:mp] = Label.new(114, 200, Game.font, "#{@stats.mp}/#{@stats.max_mp}", 0, 0, 2 * scale, 2 * scale)),
        PanelImage.new(50, 296, :icon_money, 2 * scale, 2 * scale),
        (@labels[:money] = Label.new(114, 300, Game.font, @stats.money.to_s, 0, 0, 2 * scale, 2 * scale)),
        (@labels[:level] = Label.new(50, 100, Game.font, "#{Game.text(:ui, :level)} #{@stats.level}", 0, 0, 2 * scale, 2 * scale, :top_right)),
        (@labels[:xp] = Label.new(50, 200, Game.font, "#{Game.text(:ui, :xp)} #{@stats.xp}", 0, 0, 2 * scale, 2 * scale, :top_right)),
        (@labels[:xp_to_next] = Label.new(50, 280, Game.font, Game.text(:ui, :xp_to_next, @stats.xp_to_next_level), 0, 0, scale, scale, :top_right)),
      ],
      :ui_panel, :tiled, true, scale, scale
    )
    @panel.visible = false

    @stats.on_hp_change << lambda do |hp, _|
      @labels[:hp].text = "#{hp}/#{@stats.max_hp}"
    end
    @stats.on_mp_change << lambda do |mp, _|
      @labels[:mp].text = "#{mp}/#{@stats.max_mp}"
    end
    @stats.on_money_change << lambda do |money|
      @labels[:money].text = @stats.money.to_s
    end
    @stats.on_xp_change << lambda do |xp|
      @labels[:xp].text = "#{Game.text(:ui, :xp)} #{xp}"
      @labels[:xp_to_next].text = Game.text(:ui, :xp_to_next, @stats.xp_to_next_level)
    end
    @stats.on_level_change << lambda do |level|
      @labels[:level].text = "#{Game.text(:ui, :level)} #{level}"
      @labels[:xp_to_next].text = Game.text(:ui, :xp_to_next, @stats.xp_to_next_level)
    end
  end

  def toggle
    @panel.visible = !@panel.visible
  end

  def update
    @panel.update
  end

  def draw
    @panel.draw(255, Graphics::UI_Z_INDEX)
  end
end
