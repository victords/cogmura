class Stats
  attr_reader :hp, :max_hp, :mp, :max_mp, :strength, :defense,
              :on_hp_change, :on_mp_change

  def initialize(max_hp, max_mp, strength, defense)
    @hp = @max_hp = max_hp
    @mp = @max_mp = max_mp
    @strength = strength
    @defense = defense

    @status = []

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

  def change_mp(delta)
    @mp = [[@mp + delta, 0].max, @max_mp].min
    @on_mp_change.each { |c| c.call(@mp, delta) }
  end

  def apply_status
    @status.each { |s| s.update(self) }
  end

  def remove_bad_status
    @status.delete_if(&:bad?)
  end
end
