module QuotientCube
  module Tree
    class Node
      attr_accessor :tree
    
      attr_accessor :id
      attr_accessor :name
    
      attr_accessor :dimensions
      attr_accessor :measures
    
      def initialize(tree, id, name)
        @tree = tree
      
        @id = id
        @name = name
      
        @dimensions = Dimensions.new(self)
        @measures = Measures.new(self)
      end
      
      def inspect
        "<#{id}:#{name} @dimensions=#{@dimensions.inspect} @measures=#{@measures.inspect}>"
      end
      
      def database
        tree.database
      end
      
      def meta_key(property)
        "#{tree.prefix}#{id}:#{property}"
      end
    
      def property_key(property)
        "#{tree.prefix}#{id}:[#{property}]"
      end
      
      def to_s
        "#{id} => #{name}"
      end
      
      class << self        
        def create(tree, name)
          new(tree, generate_id(tree), name)
        end
      
        def generate_id(tree)
          tree.database.addint("#{tree.prefix}last_id", 1)
        end
        
        def root(tree)
          new(tree, tree.database.get("#{tree.prefix}root"), 'root')
        end
      end
    end
  end
end