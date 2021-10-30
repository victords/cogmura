require_relative 'stats'

class BattleEnemy
  attr_reader :money, :xp, :spawns

  def initialize(type, first = false)
    @type = type

    data = Game.enemies[type] || File.open("#{Res.prefix}enemy/#{type}") do |f|
      content = f.read.chomp.split(',')
      nums = content[0..5].map(&:to_i)
      Game.enemies[type] = {
        hp: nums[0],
        mp: nums[1],
        str: nums[2],
        def: nums[3],
        money: nums[4],
        xp: nums[5],
        spawns: content[6..].map { |s| s.split(':') }.map { |a| [a[0].to_sym, a[1].to_i] }.to_h
      }
    end

    @stats = Stats.new(data[:hp], data[:mp], data[:str], data[:def])
    @money = data[:money]
    @xp = data[:xp]

    @spawns = []
    return unless first

    data[:spawns].each do |k, v|
      amount = rand(v + 1)
      amount.times { @spawns << k }
    end
  end
end
