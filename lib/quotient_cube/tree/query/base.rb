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
        def search(node, dim, value, position)
          dimension = node.dimensions.find(dim)
          
          if dimension
            # puts "Found an edge labeled #{dimension.name} from #{node.name}"
            return dimension.children.find(value)
          else
            # puts "Didn't find an edge labeled #{dim} from #{node.name}"
            
            last_dimension = last_node_dimension(node)
            last_index = tree.dimensions.index(last_dimension.name)
            
            # puts "Looking at the last child of #{last_dimension} of #{node.name}"

            if last_index < position
              last_node = last_dimension.children.last
              
              if node.nil?
                # puts "Didn't find any child nodes of the last dimension #{last_dimension} of #{node.name}"
                return node
              else
                # puts "Recursively searching #{last_node.name}"
                return search(last_node, dim, value, position)
              end
            else
              # puts "The index #{last_index} of the last dimension of #{node.name}, #{last_dimension}, wasn't less than search position #{position}, returning nil"
              return nil
            end
          end
        end
        
        #
        # Here we continue to select the last node
        #  out of the last dimension until we reach a value
        #
        def search_measures(node, measures)
          if node.measures.any?
            values = {}
            measures.each do |selected|
              measure = node.measures.find(selected)
              values[selected] = measure && measure.value
            end
              
            return values
          else
            last_dimension = last_node_dimension(node)
            
            if last_dimension.nil?
              return last_dimension
            else
              next_node = last_dimension.children.last
          
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
        
        def last_node_dimension(node)
          if node.dimensions.empty?
            return nil
          else
            tree.dimensions.reverse.each do |dimension|
              if dimension = node.dimensions.find(dimension)
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