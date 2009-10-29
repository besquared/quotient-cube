#
# Base class for querying a quotient cube tree
#
module QuotientCube
  module Tree
    module Query
      class Base
        attr_accessor :tree
        attr_accessor :conditions
        attr_accessor :measures
      
        def initialize(tree, conditions, measures)
          @tree = tree
          @conditions = conditions
          @measures = measures
        end

        #
        # Recursive search through one route of the tree
        #
        # Here if it doesn't find a child in the dimension with the label
        #  it should move to its last child and try and find a child there
        #  with that label
        #
        def search(node_id, dim, value, position)
          puts "#{node_id}, #{dim}, #{value}, #{position}"
          dimension = tree.nodes.dimension(node_id, dim)
          
          if dimension
            puts "Found an edge labeled #{dimension} from node #{node_id}"
            return tree.nodes.child(node_id, dimension, value)
          else
            puts "Didn't find an edge labeled #{dim} from #{node_id}"
            
            last_dimension = last_node_dimension(node_id)
            
            if last_dimension.nil?
              return last_dimension
            else
              last_index = tree.dimensions.index(last_dimension)
            end
            
            puts "Looking at the last child of the last dimension #{last_dimension} of #{node_id}"

            if last_index < position
              last_name = tree.nodes.children(node_id, last_dimension).last
              last_node = tree.nodes.child(node_id, last_dimension, last_name)
              
              puts "last child was #{last_name} => #{last_node}"
              
              if last_node.nil?
                puts "Didn't find any child nodes of the last dimension #{last_dimension} of #{node_id}"
                return last_node
              else
                puts "Recursively searching #{last_name}"
                return search(last_node, dim, value, position)
              end
            else
              puts "The index #{last_index} of the last dimension of #{node_id}, #{last_dimension}, wasn't less than search position #{position}, returning nil"
              return nil
            end
          end
        end
        
        #
        # Here we continue to select the last node
        #  out of the last dimension until we reach a value
        #
        def search_measures(node_id, measures)
          node_measures = tree.nodes.measures(node_id)
          if node_measures.any?
            values = {}
            measures.each do |selected|
              values[selected] = tree.nodes.measure(node_id, selected)
            end
            return values
          else
            last_dimension = last_node_dimension(node_id)
            
            if last_dimension.nil?
              return last_dimension
            else
              next_name = tree.nodes.children(node_id, last_dimension).last
              next_node = tree.nodes.child(node_id, last_dimension, next_name)
          
              if next_node.nil?
                return next_node
              else
                return search_measures(next_node, measures)
              end
            end
          end
        end
        
        #
        # Returns the last dimension
        #  for which this query has a value
        #  other than an implied '*' specified
        #
        def last_specified_position
          tree.dimensions.length.downto(1) do |index|
            return index - 1 if conditions[tree.dimensions[index - 1]] != '*'
          end

          return -1
        end
        
        def last_node_dimension(node_id)
          if tree.nodes.dimensions(node_id).empty?
            return nil
          else
            tree.dimensions.reverse.each do |dimension|
              if dimension = tree.nodes.dimension(node_id, dimension)
                return dimension
              end
            end
            
            return nil
          end
        end
      end
    end
  end
end