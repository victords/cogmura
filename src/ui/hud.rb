require 'minigl'
require_relative 'panel_image'
require_relative '../constants'

class Hud
  include MiniGL

  def initialize
    scale = Graphics::SCALE
    stats = Game.player_stats
    @labels = {}
    controls = [
      # stats
      [
        Label.new(0, 10, Game.font, "- #{Game.text(:ui, :stats)} -", 0, 0, scale, scale, :top),
        PanelImage.new(50, 100, :icon_hp, scale, scale),
        (@labels[:hp] = Label.new(114, 100, Game.font, "#{stats.hp}/#{stats.max_hp}", 0, 0, scale, scale)),
        PanelImage.new(50, 200, :icon_mp, scale, scale),
        (@labels[:mp] = Label.new(114, 200, Game.font, "#{stats.mp}/#{stats.max_mp}", 0, 0, scale, scale)),
        PanelImage.new(50, 296, :icon_money, scale, scale),
        (@labels[:money] = Label.new(114, 300, Game.font, stats.money.to_s, 0, 0, scale, scale)),
        (@labels[:level] = Label.new(50, 100, Game.font, "#{Game.text(:ui, :level)} #{stats.level}", 0, 0, scale, scale, :top_right)),
        (@labels[:xp] = Label.new(50, 200, Game.font, "#{Game.text(:ui, :xp)} #{stats.xp}", 0, 0, scale, scale, :top_right)),
        (@labels[:xp_to_next] = Label.new(50, 280, Game.font, Game.text(:ui, :xp_to_next, stats.xp_to_next_level), 0, 0, 0.5 * scale, 0.5 * scale, :top_right)),
      ],
      # items
      [
        Label.new(0, 10, Game.font, "- #{Game.text(:ui, :items)} -", 0, 0, scale, scale, :top)
      ]
    ]
    @panels = controls.map do |c|
      Panel.new(10, 10, Graphics::SCR_W - 20, Graphics::SCR_H - 20, c, :ui_panel, :tiled, true, scale, scale)
    end
    set_item_slots
    @panels.each { |p| p.visible = false }
    @panel_index = 0
    @arrow = Res.imgs(:ui_arrow, 2, 2)

    stats.on_hp_change << lambda do |hp, _|
      @labels[:hp].text = "#{hp}/#{stats.max_hp}"
    end
    stats.on_mp_change << lambda do |mp, _|
      @labels[:mp].text = "#{mp}/#{stats.max_mp}"
    end
    stats.on_money_change << lambda do |money|
      @labels[:money].text = money.to_s
    end
    stats.on_xp_change << lambda do |xp|
      @labels[:xp].text = "#{Game.text(:ui, :xp)} #{xp}"
      @labels[:xp_to_next].text = Game.text(:ui, :xp_to_next, stats.xp_to_next_level)
    end
    stats.on_level_change << lambda do |level|
      @labels[:level].text = "#{Game.text(:ui, :level)} #{level}"
      @labels[:xp_to_next].text = Game.text(:ui, :xp_to_next, stats.xp_to_next_level)
    end
    stats.on_items_change << method(:set_item_slots)
  end

  def toggle
    if @panels[@panel_index].visible
      @panels[@panel_index].visible = false
    else
      @panel_index = 0
      @panels[@panel_index].visible = true
    end
  end

  def change_panel(delta = 1)
    @panels[@panel_index].visible = false
    @panel_index += delta
    @panel_index = 0 if @panel_index >= @panels.size
    @panel_index = @panels.size - 1 if @panel_index < 0
    @panels[@panel_index].visible = true
  end

  def set_item_slots
    @panels[1].controls.slice!(1..-1)
    Game.player_stats.items.each_with_index do |(k, v), i|
      even = i % 2 == 0
      half = @panels[1].w / 2
      y = 100 + i / 2 * 80
      name = Game.text(:ui, "item_#{k}")
      scale = Graphics::SCALE
      name_size = Game.font.text_width(name) * scale
      name_slot_size = @panels[1].w / 2 - 210
      name_scale = name_size > name_slot_size ? scale * name_slot_size.to_f / name_size : scale
      @panels[1].add_component(PanelImage.new(even ? 50 : half + 25, y, "icon_#{k}", scale, scale))
      @panels[1].add_component(Label.new(even ? 114 : half + 89, y + (scale - name_scale) * Game.font.height / 2, Game.font, name, 0, 0, name_scale, name_scale))
      @panels[1].add_component(Label.new(even ? half + 25 : 50, y, Game.font, v.to_s, 0, 0, scale, scale, :top_right))
    end
  end

  def update
    return unless @panels[@panel_index].visible

    if KB.key_pressed?(Gosu::KB_LEFT)
      change_panel(-1)
    elsif KB.key_pressed?(Gosu::KB_RIGHT)
      change_panel
    end
  end

  def draw
    return unless @panels[@panel_index].visible

    @panels[@panel_index].draw(255, Graphics::UI_Z_INDEX)
    @arrow[3].draw(20, 20, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)
    @arrow[1].draw(Graphics::SCR_W - 20 - @arrow[0].width, 20, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)
  end
end
