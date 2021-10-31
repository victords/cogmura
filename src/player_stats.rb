require_relative 'stats'

class PlayerStats < Stats
  attr_reader :level, :xp, :items, :techniques, :abilities

  def initialize
    super(10, 5, 2, 0)

    @level = 1
    @xp = 0
    @money = 0

    @items = {}
    @techniques = []
    @abilities = []
  end

  def add_item(item)
    @items[item.type] ||= 0
    @items[item.type] += 1
  end
end
