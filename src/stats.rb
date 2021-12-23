class Stats
  attr_reader :hp, :max_hp, :mp, :max_mp, :strength, :defense,
              :on_hp_change, :on_mp_change

  def initialize(max_hp, max_mp, strength, defense)
    @hp = @max_hp = max_hp
    @mp = @max_mp = max_mp
    @strength = strength
    @defense = defense

    # events
    @on_hp_change = []
    @on_mp_change = []
  end

  def change_hp(delta)
    @hp = [[@hp + delta, 0].max, @max_hp].min
    @on_hp_change.each { |c| c.call(@hp, delta) }
  end

  def take_damage(damage)
    change_hp(-damage)
  end
end
