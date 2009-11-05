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
            
            if node_id.nil?
              break
            else
              Point.log("Found node #{node_id}:#{value} at #{dimension}")
            end
          end

          if node_id.nil?
            return node_id
          else
            return search_measures(node_id, measures).merge(selected)
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