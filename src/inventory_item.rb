class InventoryItem
  attr_reader :type

  def initialize(type)
    @type = type
    @data = Game.items[type]
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
