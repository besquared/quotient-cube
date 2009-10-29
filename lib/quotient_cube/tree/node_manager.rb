module QuotientCube
  module Tree
    class NodeManager
      attr_accessor :tree
      
      def initialize(tree)
        @tree = tree
      end
      
      #
      # Creation
      #
      
      def create
        database.addint("#{prefix}last_id", 1)
      end
      
      def create_root
        if root.nil?
          root_id = create
          database.put("#{prefix}root", root_id)
          return root_id
        else
          root
        end
      end
      
      #
      # We start here
      #
      
      def root
        database.get("#{prefix}root")
      end
      
      #
      # Dimension names for a node are identified as:
      #  prefix:id:dimensions => ['dim1', 'dim2', ...]
      #
      
      def dimensions(node_id)
        database.getlist("#{prefix}#{node_id}:dimensions") || []
      end
      
      def dimension(node_id, name)
        if dimensions(node_id).include?(name)
          return name
        else
          return nil
        end
      end
      
      def add_dimension(node_id, name)
        if dimensions(node_id).include?(name)
          return name
        else
          database.putdup("#{prefix}#{node_id}:dimensions", name)
          return name
        end
      end
      
      #
      # Child names for a node are identified as:
      #  prefix:id:[dim] => ['name1', 'name2', ...]
      #
      # Child pointers for a node are identified as:
      #  prefix:id:[dim]:name => id
      #
      
      def children(node_id, dimension)
        database.getlist("#{prefix}#{node_id}:[#{dimension}]") || []
      end
      
      def child(node_id, dimension, name)
        database.get("#{prefix}#{node_id}:[#{dimension}]:#{name}")
      end
      
      def add_child(node_id, dimension, name, id = nil)
        if children(node_id, dimension).include?(name)
          return child(node_id, dimension, name)
        else
          child_id = id.nil? ? create : id
          database.putdup("#{prefix}#{node_id}:[#{dimension}]", name)
          database.put("#{prefix}#{node_id}:[#{dimension}]:#{name}", child_id)
          return child_id
        end
      end
      
      #
      # Measures names for a node are identified as:
      #  prefix:id:measures => ['name1', 'name2', ...]
      #
      # Measure values for a node are identified as:
      #  prefix:id:{name} => value
      #
      
      def measures(node_id)
        database.getlist("#{prefix}#{node_id}:measures") || []
      end
      
      def measure(node_id, name)
        value = database.get("#{prefix}#{node_id}:{#{name}}")
        
        if value.nil?
          return value
        else
          return value.to_f
        end
      end
      
      def add_measure(node_id, name, value)
        if measures(node_id).include?(name)
          return measure(node_id, name)
        else
          database.putdup("#{prefix}#{node_id}:measures", name)
          database.put("#{prefix}#{node_id}:{#{name}}", value.to_s)
          return value
        end
      end
      
    protected
      def prefix
        tree.prefix
      end
      
      def database
        tree.database
      end
    end
  end
end