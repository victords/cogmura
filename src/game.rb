require 'set'
require_relative 'player_stats'

include MiniGL

class Game
  class << self
    attr_reader :font, :text_helper, :npc_texts, :on_switch_activated, :player_stats,
                :enemies, :items

    def init
      @font = ImageFont.new(:font, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"←→∞$ĞğİıÖöŞşÜü",
                            [6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                             6, 6, 6, 6, 6, 4, 6, 6, 2, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 4, 6, 6, 8, 6, 6, 6,
                             6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                             6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 2, 3, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 8, 8,
                             10, 6, 6, 6, 2, 2, 6, 6, 6, 6, 6, 6], 11, 4)
      @text_helper = TextHelper.new(@font, 1, 2, 2)

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

      @switches = Set.new
      @on_switch_activated = []

      @player_stats = PlayerStats.new
      @enemies = {}
      @items = {}

      @game_over = false
    end

    def text(category, id, *args)
      txt = @texts[category][id.to_s]
      args.each do |arg|
        txt = txt.sub('$', arg.to_s)
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

    def game_over
      @game_over = true
    end

    def over?
      @game_over
    end
  end
end
