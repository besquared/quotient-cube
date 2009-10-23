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
        cube.each_with_index do |row, index|
          next if index == cube.length - 1
      
          current = cube[index + 1]
      
          if current['upper'] != last['upper']
            puts %{
              Found new upper bound, writing 
              nodes for #{current['upper'].inspect}
            }.squish
            
            node_index[row['id']] = {
              :nodes => last_built, :upper => last['upper']
            }
            
            last_built = build_nodes(current['upper'], current)
            last = current.dup
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
            
            # puts %{
            #   Found duplicate upper bound #{current['upper'].inspect}, 
            #   comparing its lower bound #{current['lower'].inspect} to 
            #   its child's upper bound #{child[:upper].inspect}
            # }.squish
            
            cube.dimensions.each_with_index do |dimension, position|
              if child[:upper][position] == '*' and lower[position] != '*'
                
                puts %{
                  Building link from #{child[:nodes].compact.last} to 
                  #{last_built[position]} on dimension #{dimension}
                }.squish
                
                build_link(child[:nodes].compact.last, last_built[position], dimension)
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
        root = Node.create(tree, 'root')
        database.put("#{prefix}root", root.id.to_s)
        cube.measures.each do |measure|
          root.measures.create(measure, cube.first[measure])
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
            dimension = last_node.dimensions.create(dimension)
            last_node = dimension.children.create(bound[index])
            puts "Created node #{last_node}"
            nodes << last_node
          else
            nodes << nil
          end
        end
                
        cube.measures.each do |measure|
          # puts "Creating measure #{measure} => #{row[measure]} on node #{last_node}"
          last_node.measures.create(measure, row[measure].to_s)
        end
        
        nodes
      end
      
      def build_link(source, destination, dimension)
        source.dimensions.create(dimension).children.add(destination)
      end
      
      def prefix
        @prefix ||= options[:prefix].nil? ? nil : "#{options[:prefix]}:"
      end
      
      def meta_key(property)
        "#{prefix}#{property}"
      end
    end
  end
end