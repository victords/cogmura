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

  def xp_to_next_level
    # level 2: 10
    # level 3: 20
    # level 4: 40
    # level 5: 80
    # ...
    10 * 2**(@level - 1)
  end
end
