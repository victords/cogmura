require_relative 'base'

module Battle
  module Status
    class Poison < Base
      def initialize(duration, value)
        super(duration)
        @value = value
      end

      def update(target)
        super
        target.take_damage(@value)
      end

      def bad?; true; end
    end
  end
end
