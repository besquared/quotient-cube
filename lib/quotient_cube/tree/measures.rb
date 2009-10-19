module QuotientCube
  module Tree
    class Measures
      attr_accessor :node
      attr_accessor :measures
      
      def initialize(node)
        @node = node
      end
      
      def measures
        unless @measures.is_a?(Array)
          names = database.getlist(key)
          if names.nil?
            @measures = []
          else
            names = [*names]
            @measures ||= names.collect do |name|
              name = name.split(':')
              Measure.new(name.first, name.last)
            end
          end
        end
        @measures
      end
      
      def find(name)
        measures.find{|measure| measure.name == name}
      end
      
      def create(name, value)
        measure = find(name)
      
        if measure.nil?
          measure = Measure.new(name, value)
          database.putdup(key, "#{name}:#{value}") and measures.push(measure)
        end
      
        measure
      end
      
      def length
        measures.length
      end
    
      def empty?
        measures.empty?
      end
      
      def any?
        measures.any?
      end
      
      def each(&block)
        measures.each do |measure|
          yield(measure)
        end
      end
      
      def key
        node.meta_key('measures')
      end
    
      def tree
        node.tree
      end
    
      def database
        node.database
      end
    
      def to_s
        measures.to_s
      end
      
      def inspect
        measures.inspect
      end
    end
  end
end