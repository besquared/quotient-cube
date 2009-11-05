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
        def search(node_id, dim, value, position, depth = 0)
          Base.log("Entered search", "from node #{node_id}, looking for #{value} in #{dim} at position #{position}")
          
          dimension = tree.nodes.dimension(node_id, dim)
          
          if dimension
            child = tree.nodes.child(node_id, dimension, value)
            
            if child
              Base.log("Found dimension with child", "#{child}:#{value} at #{dimension}")
            else
              Base.log("Found dimension without child", "#{value} at #{dimension}")
            end
            
            return child
          else
            Base.log("Didn't find an edge", "#{dim} from node #{node_id}")
            
            # to do this properly we need to know what dimension
            #  we're on, the position that is passed in is the position
            #  we expect our value to be at, we don't know how deep
            #  we are right now but we need to know that for this
            Base.log("Looking for next dimension", "from #{node_id} at depth #{depth}")
            next_dimension = next_node_dimension(node_id, depth)
            
            if next_dimension.nil?
              return next_dimension
            else
              next_index = tree.dimensions.index(next_dimension)
            end
            
            # Base.log("Looking at the last child of the last dimension", "#{last_dimension} of node #{node_id}")

            if next_index < position
              next_name = tree.nodes.children(node_id, next_dimension).last
              next_node = tree.nodes.child(node_id, next_dimension, next_name)
              
              if next_node.nil?
                Base.log("Didn't find any child nodes of the last dimension", "#{next_dimension} of node #{node_id}")
                return next_node
              else
                Base.log("Recursively searching", "#{next_name}")
                return search(next_node, dim, value, position, depth + 1)
              end
            else
              Base.log("Terminating search", "The index #{next_index} of the next dimension of #{node_id}, #{next_dimension}, wasn't less than search position #{position}, returning nil")
              return nil
            end
          end
        end
        
        #
        # Here we continue to select the last node
        #  out of the last dimension until we reach a value
        #
        def search_measures(node_id, measures)
          Base.log("Entered search measures", "#{node_id}, #{measures}")
          
          node_measures = tree.nodes.measures(node_id)
          if node_measures.any?
            Base.log("Found measures", "#{node_id}")
            
            values = {}
            measures.each do |selected|
              values[selected] = tree.nodes.measure(node_id, selected)
            end
            return values
          else
            Base.log("Didn't find any measures", "#{node_id}")
            
            last_dimension = last_node_dimension(node_id)
            
            if last_dimension.nil?
              Base.log("Didn't find anymore dimensions", "#{node_id}")
              return last_dimension
            else
              next_name = tree.nodes.children(node_id, last_dimension).last
              next_node = tree.nodes.child(node_id, last_dimension, next_name)
          
              if next_node.nil?
                return next_node
              else
                Base.log("Recursing to search for measures", "#{next_node}, #{measures}")
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
        
        def next_node_dimension(node_id, depth)
          dimensions = tree.nodes.dimensions(node_id)
          if dimensions.empty?
            return nil
          else
            if depth >= dimensions.length
              return dimensions.last
            else
              return dimensions[depth + 1]
            end
          end
        end
        
        class << self
          def debug
            @debugging = true
            yield
            @debugging = false
          end
          
          def debugging?
            @debugging
          end
          
          def log(title, msg)
            puts "[Base Query] #{title} => #{msg}" if debugging?
          end
        end
      end
    end
  end
end