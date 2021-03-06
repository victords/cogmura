require_relative '../stats'
require_relative '../animation'

module Battle
  class Enemy < IsoGameObject
    include Animation

    SPEED = 4

    attr_reader :stats, :money, :xp, :spawns

    def initialize(type, col, row, first = false)
      _, size, img_gap_x, img_gap_y, sprite_cols, sprite_rows, _ = ENEMY_TYPE_MAP.find { |a| a[0] == type }
      super(col, row, 0, size, size, "char_#{type}", Vector.new(img_gap_x, img_gap_y), sprite_cols, sprite_rows)
      @start_pos = Vector.new(@x, @y)

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

    def choose_action
      :attack
    end

    def attack_animation(target, on_attack, on_finish)
      start_sequence(
        {
          target: target,
          speed: SPEED
        },
        {
          timer: 30,
          callback: on_attack
        },
        {
          target: @start_pos,
          speed: SPEED * 1.5,
          callback: on_finish
        }
      )
    end

    def update
      update_sequence
    end
  end
end
