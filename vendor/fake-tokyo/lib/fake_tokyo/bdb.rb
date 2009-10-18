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
      if value.is_a?(Array)
        @data[key] = value
      else
        @data[key] = [value]
      end
    end
    
    def putdup(key, value)
      @data[key] ||= []
      @data[key] << value
    end
    
    def get(key)
      data = @data[key]
      if data.nil?
        return data
      elsif data.is_a?(Array) and data.length == 1
        return data.first
      else
        return data
      end
    end
    
    def incr(key)
      if @data[key].nil?
        return @data[key] = 1
      else
        return @data[key] += 1
      end
    end
    
    def decr(key)
      if @data[key].nil?
        return @data[key] = -1
      else
        return @data[key] -= 1
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