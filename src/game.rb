require 'set'

include MiniGL

class Game
  class << self
    attr_reader :npc_texts, :on_switch_activated

    def init
      @language = 'en'
      @npc_texts = File.open("#{Res.prefix}text/#{@language}/npcs") do |f|
        f.read.split('===').map { |s| s.chomp.split("\n") }
      end
      @switches = Set.new
      @on_switch_activated = []
    end

    def switch_active?(id)
      @switches.include?(id)
    end

    def activate_switch(id)
      @switches << id
      @on_switch_activated.each { |callback| callback.call(id) }
    end
  end
end
