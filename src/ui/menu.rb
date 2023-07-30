require 'minigl'
require_relative 'panel_image'
require_relative '../constants'

class Menu
  include MiniGL

  ITEMS_PANEL_FIXED_CONTROLS = 5

  def initialize(hud)
    @hud = hud
    stats = Game.player_stats
    @labels = {}
    controls = [
      # stats
      [
        Label.new(0, 10, Game.font, "- #{Game.text(:ui, :stats)} -", 0, 0, 1, 1, :top),
        PanelImage.new(50, 110, :icon_hp, 1, 1),
        (@labels[:hp] = Label.new(158, 100, Game.font, "#{stats.hp}/#{stats.max_hp}", 0, 0, 1, 1)),
        PanelImage.new(50, 200, :icon_mp, 1, 1),
        (@labels[:mp] = Label.new(158, 200, Game.font, "#{stats.mp}/#{stats.max_mp}", 0, 0, 1, 1)),
        PanelImage.new(50, 296, :icon_money, 1, 1),
        (@labels[:money] = Label.new(158, 300, Game.font, stats.money.to_s, 0, 0, 1, 1)),
        (@labels[:level] = Label.new(50, 100, Game.font, "#{Game.text(:ui, :level)} #{stats.level}", 0, 0, 1, 1, :top_right)),
        (@labels[:xp] = Label.new(50, 200, Game.font, "#{Game.text(:ui, :xp)} #{stats.xp}", 0, 0, 1, 1, :top_right)),
        (@labels[:xp_to_next] = Label.new(50, 280, Game.font, Game.text(:ui, :xp_to_next, stats.xp_to_next_level), 0, 0, 0.5, 0.5, :top_right)),
      ],
      # items
      [
        Label.new(0, 10, Game.font, "- #{Game.text(:ui, :items)} -", 0, 0, 1, 1, :top),
      ]
    ]
    arrows = [
      PanelImage.new(10, 10, :ui_arrow, 1, 1, :top_left, 2, 2, 3),
      PanelImage.new(10, 10, :ui_arrow, 1, 1, :top_right, 2, 2, 1),
      Label.new(10, 68, Game.font, Game.text(:ui, :left_shift), 0, 0, 0.25, 0.25, :top_left),
      Label.new(10, 68, Game.font, Game.text(:ui, :right_shift), 0, 0, 0.25, 0.25, :top_right),
    ]
    @panels = controls.map do |c|
      Panel.new(0, Graphics::V_OFFSET + 130, 1000, 640, c + arrows, :ui_panel, :tiled, true, 1, 1, :top)
    end
    @panels.each { |p| p.visible = false }
    @panel_index = 0
    @select_index = 0
    set_item_slots

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
      @hud.hide
    else
      @panel_index = 0
      @panels[@panel_index].visible = true
      @hud.show(fixed: true)
    end
  end

  def visible?
    @panels[@panel_index].visible
  end

  def update
    toggle if KB.key_pressed?(Gosu::KB_RETURN)
    return unless visible?

    if KB.key_pressed?(Gosu::KB_LEFT_SHIFT)
      change_panel(-1)
    elsif KB.key_pressed?(Gosu::KB_RIGHT_SHIFT)
      change_panel
    end

    if @panel_index == 1 && @panels[1].controls.size > ITEMS_PANEL_FIXED_CONTROLS # items
      if KB.key_pressed?(Gosu::KB_LEFT) && @select_index % 2 == 1
        @select_index -= 1
      elsif KB.key_pressed?(Gosu::KB_RIGHT) && @select_index % 2 == 0 && @select_index < Game.player_stats.items.size - 1
        @select_index += 1
      elsif KB.key_pressed?(Gosu::KB_UP) && @select_index >= 2
        @select_index -= 2
      elsif KB.key_pressed?(Gosu::KB_DOWN) && @select_index < Game.player_stats.items.size - 2
        @select_index += 2
      elsif KB.key_pressed?(Gosu::KB_Z)
        item_key = Game.player_stats.items.keys[@select_index]
        if Game.items[item_key][:type] == :heal
          Game.player_stats.use_item(InventoryItem.new(item_key), Game.player_stats)
        end
      end
    end
  end

  def draw
    return unless @panels[@panel_index].visible

    @panels[@panel_index].draw(255, Graphics::UI_Z_INDEX)

    if @panel_index == 1 && @panels[1].controls.size > ITEMS_PANEL_FIXED_CONTROLS # items
      G.window.draw_rect(@panels[1].x + 15 + (@select_index % 2) * (@panels[1].w / 2 - 10),
                         @panels[1].y + 105 + @select_index / 2 * 54,
                         @panels[1].w / 2 - 20, 54, 0x33000000, Graphics::UI_Z_INDEX)
    end
  end

  private

  def change_panel(delta = 1)
    @panels[@panel_index].visible = false
    @panel_index += delta
    @panel_index = 0 if @panel_index >= @panels.size
    @panel_index = @panels.size - 1 if @panel_index < 0
    @panels[@panel_index].visible = true
  end

  def set_item_slots
    @panels[1].controls.slice!(ITEMS_PANEL_FIXED_CONTROLS..-1)
    Game.player_stats.items.each_with_index do |(k, v), i|
      even = i % 2 == 0
      half = @panels[1].w / 2
      y = 110 + i / 2 * 54
      name = Game.text(:ui, "item_#{k}")
      scale = 0.5
      name_size = Game.font.text_width(name) * scale
      name_slot_size = @panels[1].w / 2 - 210
      name_scale = name_size > name_slot_size ? scale * name_slot_size.to_f / name_size : scale
      @panels[1].add_component(PanelImage.new(even ? 20 : half + 10, y, "icon_#{k}"))
      @panels[1].add_component(Label.new(even ? 74 : half + 64, y + (scale - name_scale) * Game.font.height / 2, Game.font, name, 0, 0, name_scale, name_scale))
      @panels[1].add_component(Label.new(even ? half + 10 : 20, y, Game.font, v.to_s, 0, 0, scale, scale, :top_right))
    end
    if @select_index >= Game.player_stats.items.size && @select_index > 0
      @select_index = Game.player_stats.items.size - 1
    end
  end
end
