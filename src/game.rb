require 'set'
require_relative 'player_stats'
require_relative 'screen'
require_relative 'ui/hud'
require_relative 'ui/menu'
require_relative 'ui/message'

include MiniGL

class Game
  class << self
    attr_reader :editor, :font, :text_helper, :npc_texts, :on_switch_activated,
                :player_stats, :enemies, :items

    def init(editor: false)
      @editor = editor
      @font = ImageFont.new(:font, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"$",
                            [
                              6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                              6, 6, 6, 6, 6, 4, 6, 6, 2, 3, 5, 3, 8, 6, 6, 6, 6, 5, 5, 4, 6, 6, 8, 6, 6, 6,
                              6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                              6, 3, 6, 6, 6, 6, 6, 6, 6, 6, 2, 2, 2, 2, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 6
                            ].map { |n| 8 * n }, 88, 32)
      @text_helper = TextHelper.new(@font, Graphics::FONT_LINE_SPACING, 0.5, 0.5)

      @language = 'en'
      @texts = {}
      Dir["#{Res.prefix}text/#{@language}/*"].each do |path|
        next if path.end_with?('npcs')

        @texts[path.split('/')[-1].to_sym] = File.open(path) do |f|
          f.read.split("\n").map { |s| p = s.split("\t"); [p[0], p[-1].gsub("\\n", "\n")] }.to_h
        end
      end
      @npc_texts = File.open("#{Res.prefix}text/#{@language}/npcs") do |f|
        f.read.split('===').map { |s| s.chomp.split("\n") }
      end

      @items = {}
      File.open("#{Res.prefix}items") do |f|
        f.read.each_line do |line|
          parts = line.split("\t")
          data = parts[-1].chomp.split(',')
          @items[parts[0].to_sym] = {
            type: data[0].split('|').map(&:to_sym),
            target: data[1].to_sym,
            params: data[2].split('|')
          }
        end
      end

      @switches = Set.new
      @on_switch_activated = []

      @player_stats = PlayerStats.new
      @enemies = {}

      @game_over = false

      @screen = Screen.new(1)
      @screen.on_exit = method(:change_screen)

      @hud = Hud.new
      @menu = Menu.new(@hud)
      @message = Message.new
    end

    def change_screen(exit_obj)
      @screen = Screen.new(exit_obj.dest_scr, exit_obj.dest_entr)
      @screen.on_exit = method(:change_screen)
    end

    def text(category, id, *args)
      txt = @texts[category][id.to_s]
      args.each do |arg|
        txt = txt.sub('#', arg.to_s)
      end
      txt
    end

    def switch_active?(id)
      @switches.include?(id)
    end

    def activate_switch(id)
      @switches << id
      @on_switch_activated.each { |callback| callback.call(id) }
    end

    def set_message(type, text_id, options, on_select = nil, *msg_args)
      @hud.hide
      @message.show(type, text_id, options, on_select, *msg_args)
    end

    def game_over
      @game_over = true
    end

    def update
      # TODO remove later
      if KB.key_pressed?(Gosu::KB_R)
        init
        return
      end

      @menu.update unless @message.visible? || @screen.battle?
      unless @menu.visible?
        if @message.visible?
          @message.update
        else
          @hud.update
          @screen.update
        end
      end
    end

    def draw
      if @game_over
        @text_helper.write_line('Game Over', Graphics::SCR_W / 2, Graphics::SCR_H / 2 - 22, :center, 0xffffff, 255, nil, 0, 0, 0, 0, 4, 4)
      else
        @screen.draw
        G.window.draw_rect(0, 0, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)
        G.window.draw_rect(0, G.window.height - Graphics::V_OFFSET, G.window.width, Graphics::V_OFFSET, 0xff000000, Graphics::UI_Z_INDEX)

        @hud.draw
        @menu.draw
        @message.draw
      end
    end
  end
end
