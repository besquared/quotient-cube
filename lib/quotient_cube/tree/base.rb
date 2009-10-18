#
# A QC-Tree implementation
#
# Stores quotient cubes into key-value stores that
#  respond to put/get by serializing values using yajl
#
module QuotientCube
  module Tree
    class Base
      attr_accessor :database
      attr_accessor :options
      attr_accessor :nodes
  
      def initialize(database, options = {})
        @database = database
        @options = options
        @nodes = Nodes.new(self)
      end
  
      #
      # Measures 
      #  the list of measures you want returned
      #  ex: ['avg(sales)', 'sum(seconds)', 'avg(value)']
      # 
      # Conditions
      #  A list of dimensions with specified values
      #  ex: {'rate plan' => 'gold', 'source' => 'direct'}
      #
      def query(measures, conditions)
        query_type = :point
        conditions.each do |dimension, value|
          if value.is_a?(Array)
            query_type = :range
            break
          elsif value == :all
            query_type = :range
          
            dimension = node.root.dimensions.find(dimension)
            conditions[dimension] = dimension.children.collect{|child| child.name}
          end
        end
      
        #
        # Expand query
        #
        dimensions.each do |dimension|
          conditions[dimension] = '*' if conditions[dimension].nil?
        end
      
        #
        # Expand measures
        #
        measures = meta_query('measures') if measures == :all
      
        case query_type
        when :point
          return Query::Point.new(nodes.root, conditions, measures).process
        when :range
          return Query::Range.new(nodes.root, conditions, measures).process
        else
          raise "Unknown query type or bad conditions"
        end
      end
    
      #
      # Property
      #  the name of the meta data field you want 
      #  to retreive from the database. common fields
      #  are the list of dimensions in the qc-tree and
      #  the list of values of each dimension
      #
      def meta_query(property)
        meta_node = database.get(meta_key(property))
      end
    
      def dimensions
        @dimensions ||= meta_query('dimensions') || []
      end
      
      def meta_key(property)
        "#{prefix}#{property}"
      end
      
      def prefix
        options[:prefix].nil? ? String.new : "#{options[:prefix]}:"
      end
      
      #
      # Output
      #
      def to_dot
        nodes = []
        digraph = dot_search(nil, [], nodes)
        
        labels = []
        nodes.each{|node| labels << [node, node.split(':').last]}
        labels = labels.collect{|label| "\"#{label.first}\" [label=\"#{label.last}\"]\n"}
      
        return %{
          digraph {
            concentrate=true;
            shape=box;
            #{digraph}
            #{labels};
          }
        }
      end
    
      def dot_search(node_key = nil, path = [], nodes = [])
        digraph = ""
        node_key ||= self.class.root_key(options)
        path = [node_key] if path.empty?
      
        nodes << node_key
      
        node = lookup(node_key)
        if not node.nil?
          if node.key?('measures')
            # record measures in node here
          end
        
          dimensions = node['dimensions'] || []        
        
          if dimensions.empty?
            digraph += "\"#{path.join('" -> "')}\";\n"
          end
        
          dimensions.each_with_index do |dimension, index|
            dimension_node = lookup(self.class.dimension_key(node_key, dimension))
          
            if not dimension_node.nil?
              dimension_node.each do |value, pointer|
                if pointer.nil?
                  sub_key = "#{node_key}:#{value}"
                  digraph += dot_search(sub_key, path + [sub_key], nodes)
                else
                  digraph += "\"#{path.join('" -> "')}\" -> \"#{pointer}\" [style=dotted];\n"
                end
              end
            end
          end
        end
      
        return digraph
      end
    end
  end
end