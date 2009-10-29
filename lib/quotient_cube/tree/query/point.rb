module QuotientCube
  module Tree
    module Query
      class Point < Base
        def process(selected = {})
          node_id = tree.nodes.root
          
          tree.dimensions.each_with_index do |dimension, index|
            value = conditions[dimension]

            if value != nil and value != '*'
              node_id = search(node_id, dimension, value, index)
            end
            
            break if node_id == nil
          end

          if node_id.nil?
            return node_id
          else
            return search_measures(node_id, measures).merge(selected)
          end
        end
      end
    end
  end
end