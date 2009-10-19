module FakeTokyo
  class BDB
    attr_accessor :file
    attr_accessor :data
    attr_accessor :options
    
    def initialize
      @data = {}
    end
    
    def open(file, options = nil)
      @file = file
      @options = options
    end
    
    def put(key, value)
      if value.is_a?(String) or value.is_a?(Numeric)
        @data[key] = value.to_s
      else
        raise "Cannot convert #{value.class} into String"
      end
    end
    
    def putlist(key, values)
      @data[key] ||= []
      @data[key] += values
    end
    
    def putdup(key, value)
      @data[key] ||= []
      @data[key] << value
    end
    
    def get(key)
      @data[key]
    end
    
    alias :getlist :get

    def addint(key, value)
      if @data[key].nil?
        return @data[key] = value
      else
        return @data[key] += value
      end
    end
    
    def vanish
      data = {}
    end
    
    def close
    end
    
    def to_s
      data.to_s
    end
    
    def inspect
      data.inspect
    end
  end
end