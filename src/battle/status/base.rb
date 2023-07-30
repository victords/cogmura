module Battle
  module Status
    class Base
      def initialize(duration)
        @duration = duration
      end

      def update(_target)
        @duration -= 1
      end

      def dead?
        @duration <= 0
      end
    end
  end
end
