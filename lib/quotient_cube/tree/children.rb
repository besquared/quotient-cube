module QuotientCube
  module Tree
    class Children
      attr_accessor :dimension
      attr_accessor :children
    
      def initialize(dimension)
        @dimension = dimension
      end
    
      def children
        unless @children.is_a?(Array)
          names = database.getlist(dimension.key)
          if names.nil?
            @children = []
          else
            names = [*names]
            @children ||= names.collect do |name|
              name = name.split(':')
              Node.new(tree, name.first, name.last)
            end
          end
        end
        @children
      end
    
      def find(name)
        children.find{|child| child.name == name}
      end
    
      def create(name)
        child = find(name)
      
        if child.nil?
          child = Node.create(tree, name)
          database.putdup(dimension.key, "#{child.id}:#{child.name}") and children.push(child)
        end
      
        child
      end
      
      def add(node)
        database.putdup(dimension.key, "#{node.id}:#{node.name}") and children.push(node)
        node
      end
    
      def length
        children.length
      end
    
      def empty?
        children.empty?
      end
      
      def any?
        children.any?
      end
      
      def last
        children.last
      end
      
      def first
        children.first
      end
      
      def each(&block)
        children.each do |child|
          yield(child)
        end
      end
    
      def tree
        dimension.tree
      end
    
      def database
        dimension.database
      end
    end
  end
end