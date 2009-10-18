module QuotientCube
  module Tree
    class Nodes
      attr_accessor :tree
      attr_accessor :root
      
      def initialize(tree)
        @tree = tree
      end
      
      def root
        id = tree.database.get(tree.meta_key('root'))
        id.nil? ? id : Node.new(tree, id, 'root')
      end
    end
  end
end