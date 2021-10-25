class PlayerStats
  def initialize
    @hp = 10
    @money = 0
    @items = {}
  end

  def add_item(item)
    @items[item.type] ||= 0
    @items[item.type] += 1
  end
end
