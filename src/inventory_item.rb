class InventoryItem
  attr_reader :key

  def initialize(key)
    @key = key
    @data = Game.items[key]
  end

  def target_type
    @data[:target]
  end

  # target is a Stats
  def use(target)
    @data[:type].each do |type|
      case type
      when :heal
        target.change_hp(@data[:params][0].to_i)
      when :heal_status
        target.remove_bad_status
      when :boost
        target.boost(@data[:params][0].to_i)
      end
    end
  end
end
