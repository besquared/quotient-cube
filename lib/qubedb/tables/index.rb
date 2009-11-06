module Qubedb
  module Tables
    class Index
      attr_accessor :table
      attr_accessor :name
      
      def initialize(table, name)
        @table = table
        @name = name
      end
    end
  end
end