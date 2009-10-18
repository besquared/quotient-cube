module QuotientCube
  module Tree
    module Query
      class Point < Base
        def process
          node = tree.nodes.root
          
          tree.dimensions.each_with_index do |dimension, index|
            value = conditions[dimension]

            if value != nil and value != '*'
              node = search(node, dimension, value, index)
            end
            
            break if node == nil
          end

          if node.nil?
            return node
          else
            return search_measures(node, measures)
          end
        end
      end
    end
  end
end