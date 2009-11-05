module QuotientCube
  module Tree
    module Query
      class Range < Base
        def process(node = tree.nodes.root, position = 0, cell = {}, results = [])          
          Range.log("Entering process", "from node #{node}")
          
          if position > last_specified_position
            Range.log("Terminating search", "position #{position} > last specified position #{last_specified_position}")
            if not node.nil?
              Range.log("Found the end of a path", "finding measures #{measures.inspect} closest to #{node}")
              results << search_measures(node, measures).merge(cell)
            end
        
            return results
          end
      
          # Loop over dimensions until we have the next condition that isn't '*'
          #  if we're at the end, recurse to add the measures from the last node
          #  we found to the final result set
        
          values = nil
          dimension = nil
          position.upto(tree.dimensions.length - 1) do |index|
            dimension = tree.dimensions[index]
            values = conditions[dimension]
        
            if not values == '*'
              position = index
              break
            elsif index == tree.dimensions.length - 1
              # we've run out of possible dimensions
              Range.log("Search terminating", "we've run out of possible dimensions to search")
              process(node, index, cell, results)
          
              return results
            end
          end
      
          Range.log("Searching through node #{node} for values #{values.inspect}")
      
          saved_node = node
          if not values.is_a?(Array)
            Range.log("Searching for point value", "#{values}")
            node = search(node, dimension, values, position)
        
            if node.nil?
              Range.log("Didn't find an edge labeled #{values} off of #{saved_node}", "pruning branch")
            else
              Range.log("Found an edge labeled #{values} from #{node}", "recursing on #{dimension} => #{values}")
              process(node, position + 1, cell.merge(dimension => values), results)
            end
          else
            values.each do |value|
              node = search(saved_node, dimension, value, position)          
              if node.nil?
                Range.log("Didn't find an edge labeled #{value} off of #{saved_node}", "pruning branch")
              else
                Range.log("Found an edge labeled #{value} off of #{saved_node}", "recursing on #{dimension} => #{value}")
                process(node, position + 1, cell.merge(dimension => value), results)
              end
            end
        
            return results
          end
        end        
        
        class << self
          def log(title, msg = nil)
            puts "[Range Query] #{title} => #{msg}" if QuotientCube::Tree::Query::Base.debugging?
          end
        end
      end
    end
  end
end