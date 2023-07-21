require 'minigl'
require_relative 'panel_image'
require_relative '../constants'

class Menu
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
        (@labels[:hp] = Label.new(158, 100, Game.font, "#{stats.hp}/#{stats.max_hp}", 0, 0, scale, scale)),
        PanelImage.new(50, 200, :icon_mp, scale, scale),
        (@labels[:mp] = Label.new(158, 200, Game.font, "#{stats.mp}/#{stats.max_mp}", 0, 0, scale, scale)),
        PanelImage.new(50, 296, :icon_money, scale, scale),
        (@labels[:money] = Label.new(158, 300, Game.font, stats.money.to_s, 0, 0, scale, scale)),
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
    @panels.each { |p| p.visible = false }
    @panel_index = 0
    @select_index = 0
    set_item_slots

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

  def visible?
    @panels[@panel_index].visible
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
      y = 100 + i / 2 * 98
      name = Game.text(:ui, "item_#{k}")
      scale = Graphics::SCALE
      name_size = Game.font.text_width(name) * scale
      name_slot_size = @panels[1].w / 2 - 210
      name_scale = name_size > name_slot_size ? scale * name_slot_size.to_f / name_size : scale
      @panels[1].add_component(PanelImage.new(even ? 50 : half + 25, y, "icon_#{k}"))
      @panels[1].add_component(Label.new(even ? 158 : half + 133, y + (scale - name_scale) * Game.font.height / 2, Game.font, name, 0, 0, name_scale, name_scale))
      @panels[1].add_component(Label.new(even ? half + 25 : 50, y, Game.font, v.to_s, 0, 0, scale, scale, :top_right))
    end
    if @select_index >= Game.player_stats.items.size && @select_index > 0
      @select_index = Game.player_stats.items.size - 1
    end
  end

  def set_message(type, message, &block)
    @message_bg = Res.img("ui_#{type}")
    @message = message
    @on_message_close = block
  end

  def update
    if @message && (KB.key_pressed?(Gosu::KB_RETURN) || KB.key_pressed?(Gosu::KB_Z))
      @message = nil
      @on_message_close.call
      return
    end

    toggle if KB.key_pressed?(Gosu::KB_RETURN)
    return unless @panels[@panel_index].visible

    if KB.key_pressed?(Gosu::KB_LEFT_SHIFT)
      change_panel(-1)
    elsif KB.key_pressed?(Gosu::KB_RIGHT_SHIFT)
      change_panel
    end

    if @panel_index == 1 && @panels[1].controls.size > 1 # items
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
    if @message
      G.window.draw_rect(0, 0, Graphics::SCR_W, Graphics::SCR_H, 0x80000000, Graphics::UI_Z_INDEX)
      x = (Graphics::SCR_W - @message_bg.width) / 2
      y = (Graphics::SCR_H - @message_bg.height) / 2
      @message_bg.draw(x, y, Graphics::UI_Z_INDEX)
      Game.text_helper.write_breaking(@message, x + 50, y + 50, @message_bg.width - 100, :left, 0, 255, Graphics::UI_Z_INDEX)
    end

    return unless @panels[@panel_index].visible

    @panels[@panel_index].draw(255, Graphics::UI_Z_INDEX)
    @arrow[3].draw(20, 20, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)
    @arrow[1].draw(Graphics::SCR_W - 20 - @arrow[0].width, 20, Graphics::UI_Z_INDEX, Graphics::SCALE, Graphics::SCALE)

    if @panel_index == 1 && @panels[1].controls.size > 1 # items
      G.window.draw_rect(55 + (@select_index % 2) * (Graphics::SCR_W / 2 - 35), 105 + @select_index / 2 * 98, Graphics::SCR_W / 2 - 75, 98, 0x33000000, Graphics::UI_Z_INDEX)
    end
  end
end
