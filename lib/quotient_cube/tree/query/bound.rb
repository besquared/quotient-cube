#
# Query used internally to find upper 
#  bounds during incremental maintanence
#
module QuotientCube
  module Tree
    module Query
      class Bound < Base
        def process
          node_id = tree.nodes.root
          
          # keep a running list of the 
          # dimensions and values that we've visited
          tree.dimensions.each_with_index do |dimension, index|
            value = conditions[dimension]

            if value != nil and value != '*'
              node_id = search(node_id, dimension, value, index)
            end
            
            break if node_id.nil?
            Point.log("Found node #{node_id}:#{value} at #{dimension}") unless value.nil?
          end

          if node_id.nil?
            return node_id
          else
            # Instead of searching for measures
            #  here we need to traverse the same way
            #  but keep track of the dimensions and nodes
            #  we're passing through as we go. 
            #  Maybe a 'search_bound' method?
            return search_bound(node_id, measures)
          end
        end

        #
        # Here we continue to select the last node
        #  out of the last dimension until we reach a value
        #
        # This is just like search_measures only
        #   it records where we go as we go so that
        #   we can get our overall bound when we're done
        #
        def search_bound(node_id, bound = [])
          Base.log("Entered search bound", "#{node_id}")
          
          if tree.nodes.measures(node_id).any?
            Base.log("Found measures in #{node_id}")
            
            values = {}
            
            return values
          else
            Base.log("Didn't find any measures in #{node_id}")
            
            dimensions = order(tree.nodes.dimensions(node_id))
            
            Base.log("node #{node_id} has dimensions #{dimensions.inspect}")
            
            if dimensions.nil?
              Base.log("Didn't find any dimension from #{node_id}")
              return nil
            else
              last_dimension = dimensions.last
              next_name = tree.nodes.children(node_id, dimensions.last).last
              next_node = tree.nodes.child(node_id, dimensions.last, next_name)
          
              if next_node.nil?
                return next_node
              else
                Base.log("Recursing to search for measures in #{next_node}")
                return search_bound(next_node)
              end
            end
          end
        end
        
        class << self
          def log(title, msg = nil)
            puts "[Point Query] #{title} => #{msg}" if QuotientCube::Tree::Query::Base.debugging?
          end
        end
      end
    end
  end
end