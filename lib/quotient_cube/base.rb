include AutobotsTransform

#
# Requires a table object with random
#  access, we should probably write one
#  that can stream off of disk at some point
#
# This doesn't generate quite the right id's
#  unless you use an ordered hash to store the
#  inverted indexes in.
#
# It's important to note that we're using dimension
#  names in indexes everywhere to make sure that we
#  can do cubes only for the dimensions we're interested
#  in and not every dimension in the table
#
module QuotientCube
  class Base < AutobotsTransform::Table
    attr_accessor :table
    attr_accessor :dimensions
    attr_accessor :measures
    attr_accessor :values
  
    def initialize(table, dimensions, measures)
      @table = table
      @dimensions = dimensions
      @measures = measures
      super(:column_names => ['id', 'upper', 'lower', 'child_id', *measures])
    end
  
    def build(&block)
      cell = Array.new(dimensions.length).fill('*')
      dfs(cell, (0..table.data.length - 1).to_a, 0, -1, &block)
      self.sort(['upper', 'id'])
    end
    
    def update(tree, &block)
      cell = Array.new(dimensions.length).fill('*')
      ddfs(tree, cell, (0..table.data.length - 1).to_a, 0, -1, &block)
      self.sort(['upper', 'id'])
    end
    
    #
    # Returns a list of each dimension
    #  with an array of values that appear
    #  in that dimension
    #
    # {'product' => ['P1', 'P2'], 'season' => ['s', 'f]}
    #
    def values
      if @values
        return @values
      else
        values = {}
        table.each do |row|
          dimensions.each do |dimension|
            values[dimension] ||= []
            values[dimension] << row[dimension]
          end
        end
        
        values.keys.each do |dimension|
          values[dimension].uniq!
          values[dimension].sort!
        end
        
        @values = values
      end
    end
    
    #
    # Collects statistics about the rows
    #  in the current partition we're searching
    #
    # [
    #  {"S1"=>[0, 1], "S2"=>[2]}, 
    #  {"P1"=>[0, 2], "P2"=>[1]}, 
    #  {"f"=>[2], "s"=>[0, 1]}
    # ]
    #
    def indexes(pointers)
      indexes = {}
      dimensions.each do |dimension|
        index = {}
        columni = table.column_names.index(dimension)
        pointers.each do |rowi|
          value = table.data[rowi][columni]
          index[value] ||= []
          index[value] << rowi
        end
        # puts "Setting indexes[#{dimension}] to #{index.inspect}"
        indexes[dimension] = index
      end
      indexes
    end

    #
    # the upper bound is the same as the lower bound for every 
    # value of the lower bound that isn't '*'
    #
    # for any value of the lower bound that is '*' if there
    #  is a single value that appears in every tuple of the
    #  partition that we're looking over, then the value
    #  of the upper bound for that dimension is the value
    #  that appears in every tuple
    #
    # This is the 'jumping' described in the literature
    #
    # Example: if our partition is:
    # (2, 1, 1), (2, 1, 2)
    #
    # and our lower bound is
    # (2, *, *) 
    #
    # our upper bound is
    # (2, 1, *)
    #
    def upper_bound(indexed, lower)
      upper = lower.dup
      lower.each_with_index do |value, index|
        dimension = dimensions[index]
        
        if value == '*'
          if indexed[dimension].keys.length == 1
            upper[index] = indexed[dimension].keys.first
          end
        else
          upper[index] = value
        end
      end
      upper
    end
  
    def dfs(cell, pointers, position, child, &block)
      # puts table.to_s
      
      # Computer aggregate of cell
      aggregate = block.call(table, pointers) if block_given?
      
      # Collect information about the partition
      indexed = indexes(pointers)
      
      # Compute the upper bound of the class containing cell
      #  by 'jumping' to the appropriate upper bound
      upper = upper_bound(indexed, cell)
    
      class_id = self.length
      # puts "Recording class [#{class_id}, #{upper.inspect}, #{cell.inspect}, #{child}]"
      self << [class_id, upper.dup, cell.dup, child, *aggregate]
      
      # puts "Found class #{class_id} (#{child}) => #{upper}"
      # puts cell.inspect
      # puts upper.inspect
    
      # return if we've examined this upper bound before
      #  I don't think this is working
      for j in (0..position - 1) do
        return if cell[j] == '*' and upper[j] != '*'
      end
      
      d = upper.dup
      n = dimensions.length - 1
      for j in (position..n) do
        next unless d[j] == '*'
        
        dimension = dimensions[j]
        indexed[dimension].keys.sort.each do |x|
          pointers = indexed[dimension][x]
          if(pointers.length > 0)
            d[j] = x
            dfs(d, pointers, j, class_id, &block)
            d[j] = '*'
          end
        end
      end
    end
    
    #
    # Delta DFS for updating a qc-tree in batch
    #
    def ddfs(tree, cell, pointers, position, child, &block)
      # Computer aggregate of cell
      #  this might be different here if we're updating
      aggregate = block.call(table, pointers) if block_given?
      
      # Collect information about the partition
      indexed = indexes(pointers)
    
      # Compute the upper bound of the class containing cell
      #  by 'jumping' to the appropriate upper bound
      upper = upper_bound(indexed, cell)
      
      #
      # Look in the tree for the upper bound (ub) of the class containing c
      #
      #  If we can't find it record a new class like we normally would
      #
      #  If we do find ub then we compare it to c' (upper), we have 3 cases
      #  
      #  1) ub ^ c' = ub
      #     We found the exact upper bound in the tree
      #      Record a measure update on the class
      #  2) ub ^ c' = c'
      #     c' is an upper bound bound. Record a split class
      #     with upper bound c' containing all cells of C that
      #     are below c'. The remainder of C forms another class
      #     with ub as its upper bound. (????)
      #  3) Neither of the above.
      #     ub and c' are not comparable. Record a new class with
      #     upper bound c'' = ub ^ c'
      #
      class_id = self.length
      self << [class_id, upper.dup, cell.dup, child, *aggregate]
    
      # puts "Found class #{class_id} (#{child}) => #{upper}"
      # puts cell.inspect
      # puts upper.inspect
    
      # return if we've examined this upper bound before
      for j in (0..position - 1) do
        return if cell[j] == '*' and upper[j] != '*'
      end
            
      d = upper.dup
      n = dimensions.length - 1
      for j in (position..n) do
        next unless d[j] == '*'
        
        dimension = dimensions[j]
        indexed[dimension].each do |x, pointers|
        if(pointers.length > 0)
            d[j] = x
            dfs(tree, d, pointers, j, class_id, &block)
            d[j] = '*'
          end
        end
      end
    end
  
    class << self
      def build(table, dimensions, measures, &block)
        new(table, dimensions, measures).build(&block)
      end
    end
  end
end