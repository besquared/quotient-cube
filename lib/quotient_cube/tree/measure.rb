module QuotientCube
  module Tree
    class Measure
      attr_accessor :name
      attr_accessor :value
      
      def initialize(name, value)
        @name = name
        @value = value
      end
      
      def value
        @value.to_f
      end
    end
  end
end