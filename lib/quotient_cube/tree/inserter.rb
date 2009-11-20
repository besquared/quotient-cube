module QuotientCube
  module Tree
    class Inserter
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
      
      def apply
        return if cube.length == 0
        
        build_root
                
        # if we're all * the node index should point us to real root
        #  if we aren't all stars the node index should point us to
        #  the last thing built, I see now, if there were no nodes
        #  built we need to use the root node (it was the last built)
        
        last = cube.first.dup
        last_built = build_nodes(last['upper'], last)
        last_built = [tree.nodes.root] if last_built.compact.empty?
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
      
      
      def build_root(current = cube.first)        
        root = tree.nodes.create_root
        Builder.log("Created root node", "#{root}")
        
        cube.measures.each do |measure|
          # Builder.log("Writing measure #{measure}:#{cube.first[measure]} to #{root}")
          tree.nodes.add_measure(root, measure, cube.first[measure])
        end
      end
      
      #
      # Stores one upper bound in the database
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
          # Builder.log("Writing measure #{measure}:#{row[measure]} to #{last_node}")
          tree.nodes.add_measure(last_node, measure, row[measure])
        end
        
        nodes
      end
      
      class << self
        def apply(database, cube, options = {})
          new(database, cube, options).build
        end
        
        def debug
          @debugging = true
          begin
            yield
          ensure
            @debugging = false
          end
        end
        
        def debugging?
          @debugging
        end
        
        def log(title, msg = nil)
          puts "[Inserter] #{title} => #{msg}" if debugging?
        end
      end
    end
  end
end