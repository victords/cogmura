require_relative 'stats'

class PlayerStats < Stats
  attr_reader :level, :xp, :money, :items, :techniques, :abilities,
              :on_xp_change, :on_level_change, :on_money_change, :on_items_change

  def initialize
    super(10, 5, 2, 0)

    @xp = 0
    @level = 1
    @money = 0
    @hp_boost = 0

    @items = {}
    @techniques = []
    @abilities = []

    # events
    @on_xp_change = []
    @on_level_change = []
    @on_money_change = []
    @on_items_change = []
  end

  def add_item(key)
    @items[key] ||= 0
    @items[key] += 1
    @on_items_change.each(&:call)
  end

  def remove_item(key)
    @items[key] -= 1
    @items.delete(key) if @items[key] <= 0
    @on_items_change.each(&:call)
  end

  def use_item(item, target)
    remove_item(item.key)
    item.use(target)
  end

  def xp_to_next_level
    total_xp_to_level(@level + 1) - @xp
  end

  def xp_delta
    total_xp_to_level(@level + 1) - total_xp_to_level(@level)
  end

  def xp=(value)
    @xp = value
    @on_xp_change.each { |c| c.call(@xp) }
    return unless @xp >= total_xp_to_level(@level + 1)

    @level += 1
    @on_level_change.each { |c| c.call(@level) }
  end

  def money=(value)
    @money = value
    @on_money_change.each { |c| c.call(@money) }
  end

  def recover
    hp_delta = @max_hp - @hp
    change_hp(hp_delta) if hp_delta > 0
    mp_delta = @max_mp - @mp
    change_mp(mp_delta) if mp_delta > 0
  end

  def boost(percent)
    amount = (percent.to_f / 100 * @max_hp).round
    @hp_boost += amount
    @max_hp += amount
    change_hp(amount)
  end

  def remove_boost
    @max_hp -= @hp_boost
    change_hp(-@hp_boost)
    @hp_boost = 0
  end

  private

  def total_xp_to_level(level)
    # level 2: 10
    # level 3: 30 (10 + 20)
    # level 4: 70 (10 + 20 + 40)
    # level 5: 150 (10 + 20 + 40 + 80)
    # ...
    10 * (2**(level - 1) - 1)
  end
end
