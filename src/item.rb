require_relative 'game'

class Item
  attr_reader :type

  def initialize(type)
    @type = type
    @data = Game.items[type] || File.open("#{Res.prefix}item/#{type}") do |f|
      content = f.read.chomp.split(',')
      Game.items[type] = {
        type: content[0].to_sym,
        target: content[1].to_sym,
        amount: content[2].to_i
      }
    end
  end

  def target_type
    @data[:target]
  end

  # target is a Stats
  def use(target)
    case @data[:type]
    when :heal
      target.change_hp(@data[:amount])
    end
  end
end
