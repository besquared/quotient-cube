module QuotientCube
  module Tree
    class Dimension
      attr_accessor :node
      attr_accessor :name
      attr_accessor :children
    
      def initialize(node, name)
        @node = node
        @name = name
        @children = Children.new(self)
      end
    
      def key
        node.property_key(name)
      end
    
      def tree
        node.tree
      end
    
      def database
        node.database
      end
      
      def to_s
        name
      end
    
      # def to_s
      #   str = ""
      #   children.each do |child|
      #     str += child.to_s
      #   end
      #   str
      # end
    end
  end
end