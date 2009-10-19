module FakeTokyo
  class HDB
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
      @data[key] = value
    end
    
    def get(key)
      @data[key]
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