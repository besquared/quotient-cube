module QuotientCube
  module Tree
    class Dimensions
      attr_accessor :node
      attr_accessor :dimensions
    
      def initialize(node)
        @node = node
      end
    
      def dimensions
        unless @dimensions.is_a?(Array)
          names = database.get(key)
          if names.nil?
            @dimensions = []
          else
            names = [*names]
            @dimensions ||= names.collect do |name| 
              Dimension.new(node, name)
            end
          end
        end
        @dimensions
      end
    
      def find(name)
        dimensions.find{|dimension| dimension.name == name}
      end
    
      def create(name)
        dimension = find(name)
      
        if dimension.nil?
          dimension = Dimension.new(node, name)
          database.putdup(key, name) and dimensions.push(dimension)
        end
      
        dimension
      end
    
      def length
        dimensions.length
      end
    
      def empty?
        dimensions.empty?
      end
      
      def first
        dimensions.first
      end
      
      def last
        dimensions.last
      end
      
      def each(&block)
        dimensions.each do |dimension|
          yield(dimension)
        end
      end
      
      def to_s
        dimensions.to_s
      end
      
      def inspect
        dimensions.inspect
      end
    
      def key
        node.meta_key('dimensions')
      end
    
      def tree
        node.tree
      end
    
      def database
        node.database
      end
    end
  end
end