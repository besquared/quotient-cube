module QuotientCube
  module Tree
    class Builder
      attr_accessor :database
      attr_accessor :cube
      attr_accessor :options      
      attr_accessor :node_index
      
      attr_accessor :tree
      
      def initialize(database, cube, options = {})
        @database = database
        @cube = cube
        @options = options
        @node_index = {}
        
        @tree = Tree::Base.new(database, options)
      end
      
      def build
        return if cube.length == 0
        
        build_meta
        build_root
        
        # this isn't right, it thinks we already
        #  built the upper of the first row, but we
        #  never did, we need to do that
      
        last = cube.first
        last_built = [tree.nodes.root]
        node_index[0] = {:nodes => last_built, :upper => last['upper']}
        
        cube.each_with_index do |row, index|
          next if index == cube.length - 1
      
          current = cube[index + 1]
          
          if current['upper'] != last['upper']
            Builder.log("Found new upper bound", "writing nodes for #{current['upper'].inspect}")
            
            last_built, last = build_nodes(current['upper'], current), current.dup            
            node_index[current['id']] = {:nodes => last_built, :upper => last['upper']}
          else
            #
            # If we've found a new
            #  upper bound we need to compare the current lower bound
            #  to the child upper bound, and find out which dimension
            #  we need to create a link on, once we've done that
            #  we create a link from the child node to the current
            #  upper bound node on that dimension
            #
            
            lower = current['lower']
            child = node_index[current['child_id']]
            
            Builder.log("Found duplicate upper bound", %{
              #{current['upper'].inspect}, 
              comparing its lower bound #{current['lower'].inspect} to 
              its child's upper bound #{child[:upper].inspect}
            }.squish)
            
            cube.dimensions.each_with_index do |dimension, position|
              if child[:upper][position] == '*' and lower[position] != '*'
                
                # Builder.log("Building link", %{
                #   from #{child[:nodes].compact.last} -> 
                #   #{last_built[position]} on dimension #{dimension}
                # }.squish)
                
                build_link(child[:nodes].compact.last, last_built[position], lower[position], dimension)
                break
              end
            end
          end
        end
        
        tree
      end
      
      def build_meta
        database.putlist(meta_key('dimensions'), cube.dimensions)
        database.putlist(meta_key('measures'), cube.measures)
        
        cube.fixed.each do |dimension, value|
          database.putdup(meta_key('fixed'), "#{dimension}:#{value}")
        end
        
        cube.values.each do |dimension, values|
          database.putlist(meta_key("[#{dimension}]"), values)
        end
      end
      
      def build_root
        root = tree.nodes.create_root
        cube.measures.each do |measure|
          tree.nodes.add_measure(root, measure, cube.first[measure])
        end
      end
      
      #
      # Stores one upper bound in the database
      #
      #
      # Christ almighty what have we done here, this is terrible
      #
      def build_nodes(bound, row)
        nodes = []
        
        last_node = tree.nodes.root
        cube.dimensions.each_with_index do |dimension, index|
          if bound[index] != '*'
            dimension = tree.nodes.add_dimension(last_node, dimension)
            last_node = tree.nodes.add_child(last_node, dimension, bound[index])
            Builder.log("Building node", "#{last_node} at #{dimension} labeled #{bound[index]}")
            nodes << last_node
          else
            nodes << nil
          end
        end
                
        cube.measures.each do |measure|
          tree.nodes.add_measure(last_node, measure, row[measure])
        end
        
        nodes
      end
      
      def build_link(source, destination, name, dimension)
        dimension = tree.nodes.add_dimension(source, dimension)
        linked = tree.nodes.add_child(source, dimension, name, destination)
        Builder.log("Building link", "#{source} to #{destination} at #{dimension} labeled #{name}")
      end
      
      def prefix
        @prefix ||= options[:prefix].nil? ? nil : "#{options[:prefix]}:"
      end
      
      def meta_key(property)
        "#{prefix}#{property}"
      end
      
      class << self
        def build(database, cube, options = {})
          new(database, cube, options).build
        end
        
        def debug
          @debugging = true
          yield
          @debugging = false
        end
        
        def debugging?
          @debugging
        end
        
        def log(title, msg)
          puts "[Builder] #{title} => #{msg}" if debugging?
        end
      end
    end
  end
end