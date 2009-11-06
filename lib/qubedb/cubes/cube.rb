module Qubedb
  module Cubes
    class Cube
      attr_accessor :database
      attr_accessor :name
    
      def initialize(database, name)
        @database = database
        @name = name
      end
    end
  end
end