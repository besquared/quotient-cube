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
        #  we should move to its last dimension and try and find a child there
        #  with that label
        #
        def search(node_id, dim, value, position)
          Base.log("Entered search", "from node #{node_id}, looking for #{value} in #{dim} at position #{position}")
            
          dimensions = order(tree.nodes.dimensions(node_id))
          
          # if node has a child or link pointing 
          #  to dim labeled value return it
          if dimensions.include?(dim)
            if child = tree.nodes.child(node_id, dim, value)
              Base.log("Found dimension with child", "#{child}:#{value} at #{dim}")
              return child
            else
              Base.log("Found dimension without child", "#{value} at #{dim}")
            end
          else
            Base.log("Didn't find an edge", "#{dim} from node #{node_id}")
          end
          
          return nil if dimensions.empty?
          
          # if tree.dimensions.index(dimensions.last) < position
            last_name = tree.nodes.children(node_id, dimensions.last).last
            last_node = tree.nodes.child(node_id, dimensions.last, last_name)
            
            if last_node.nil?
              Base.log("Didn't find any child nodes of the last dimension", "#{dimensions.last} of node #{node_id}")
              return last_node
            else
              Base.log("Recursively searching", "#{last_name}")
              return search(last_node, dim, value, position)
            end
          # else
          #   Base.log("Terminating search", "#{dimensions.length - 1} is < position")
          #   return nil
          # end
        end
        
        #
        # Here we continue to select the last node
        #  out of the last dimension until we reach a value
        #
        def search_measures(node_id, measures)
          Base.log("Entered search measures", "#{node_id}, #{measures}")
          
          if tree.nodes.measures(node_id).any?
            Base.log("Found measures in #{node_id}")
            
            values = {}
            measures.each do |selected|
              values[selected] = tree.nodes.measure(node_id, selected)
            end
            return values
          else
            Base.log("Didn't find any measures in #{node_id}")
            
            dimensions = order(tree.nodes.dimensions(node_id))
            
            puts "node #{node_id} has dimensions #{dimensions.inspect}"
            
            if dimensions.nil?
              Base.log("Didn't find any dimension from #{node_id}")
              return nil
            else
              next_name = tree.nodes.children(node_id, dimensions.last).last
              next_node = tree.nodes.child(node_id, dimensions.last, next_name)
          
              if next_node.nil?
                return next_node
              else
                Base.log("Recursing to search for measures in #{next_node}")
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
        
        def order(dimensions)
          tree.dimensions & dimensions
        end
                
        class << self
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
            if msg
              puts "[Base Query] #{title} => #{msg}" if debugging?
            else
              puts "[Base Query] #{title}" if debugging?
            end
          end
        end
      end
    end
  end
end