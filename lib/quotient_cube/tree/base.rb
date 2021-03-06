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
        @nodes = NodeManager.new(self)
      end
    
      # 
      # Conditions = {}
      #  A list of dimensions with specified values
      #  ex: {'rate plan' => 'gold', 'source' => 'direct'}
      #  ex: {'rate plan' => :all, 'source' => 'direct'}
      #
      # Measures = :all
      #  the list of measures you want returned
      #  ex: :all, ['avg(sales)', 'sum(seconds)', 'avg(value)']
      #
      def find(*args)
        options = args.pop if args.last.is_a?(Hash)
        
        measures = args.first == :all ? args.first : args
        conditions = (options and options[:conditions]) || {}
        selected = conditions.dup
        
        query_type = :point
        conditions.each do |dimension, value|
          if value.is_a?(Array)
            query_type = :range
          elsif value == :all
            # Expand conditions
            conditions[dimension] = values(dimension)
            query_type = :range
          end
        end
        
        # Expand measures
        measures = meta_query('measures') if measures == :all
        
        case query_type
        when :point
          return Query::Point.new(self, conditions, measures).process(selected)
        when :range
          # Fill in conditions
          dimensions.each do |dimension|
            conditions[dimension] = '*' if conditions[dimension].nil?
          end
          
          # puts "Range query for #{measures.inspect} on #{conditions.inspect}"
          
          return Query::Range.new(self, conditions, measures).process
        end
      end
      
      def meta_query(property)
        meta_node = database.getlist(meta_key(property))
      end
    
      def dimensions
        @dimensions ||= meta_query('dimensions') || []
      end
            
      def measures
        @measures ||= meta_query('measures') || []
      end
      
      def values(dimension)
        @values ||= {}
        @values[dimension] ||= meta_query("[#{dimension}]") || []
      end
      
      def prefix
        options[:prefix].nil? ? String.new : "#{options[:prefix]}:"
      end
      
      def meta_key(property)
        "#{prefix}#{property}"
      end
    end
  end
end