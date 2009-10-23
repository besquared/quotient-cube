require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe QuotientCube::Base do
  describe "With the store, product, season data set" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'store', 'product', 'season', 'sales'
        ], :data => [
          ['S1', 'P1', 's', 6],
          ['S1', 'P2', 's', 12],
          ['S2', 'P1', 'f', 9]
        ]
      )
    
      @dimensions = ['store', 'product', 'season']
      @measures = ['sales']
    end
  
    it "should index correctly" do
      cube = QuotientCube::Base.new(
        Table.new(
          :column_names => ['store', 'product'], 
          :data => [['S1', 'P1'], ['S1', 'P2']]
        ), ['store', 'product'], []
      )
    
      cube.indexes([0,1]).should == {
        'store' => {'S1' => [0, 1]}, 
        'product' => {'P1' => [0], 'P2' => [1]}
      }
    end
  
    it "should find upper bounds correctly" do
      cube = QuotientCube::Base.new(@table, @dimensions, @measures)
    
      cube.upper_bound(
        cube.indexes([0, 1]), ['S1', '*', '*']
      ).should == ['S1', '*', 's']
    end
  
    it "should build temporary classes correctly" do
      cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        sum / pointers.length.to_f      
      end
        
      cube.length.should == 11
    
      # this is absolutely correct, never change this again
    
      ids = [0, 5, 1, 9, 2, 6, 3, 8, 4, 7, 10]
    
      uppers = [
        ['*', '*', '*'], ['*', 'P1', '*'], ['S1', '*', 's'],
        ['S1', '*', 's'], ['S1', 'P1', 's'], ['S1', 'P1', 's'],
        ['S1', 'P2', 's'], ['S1', 'P2', 's'], ['S2', 'P1', 'f'],
        ['S2', 'P1', 'f'], ['S2', 'P1', 'f']
      ]
    
      lowers = [
        ['*', '*', '*'], ['*', 'P1', '*'],['S1', '*', '*'],
        ['*', '*', 's'], ['S1', 'P1', 's'], ['*', 'P1', 's'],
        ['S1', 'P2', 's'], ['*', 'P2', '*'], ['S2', '*', '*'],
        ['*', 'P1', 'f'], ['*', '*', 'f']
      ]
    
      aggregates = [
        9, 7.5, 9, 9, 6, 6, 12, 12, 9, 9, 9
      ]
    
      uppers.zip(lowers).each_with_index do |pair, index|
        cube[index]['id'].should == ids[index]
        cube[index]['upper'].should == pair.first
        cube[index]['lower'].should == pair.last
        cube[index]['sales'].should == aggregates[index]
      end
    end
    
    it "should do aggregate multiple measures" do
      cube = QuotientCube::Base.build(
        @table, @dimensions, ['sum(sales)', 'avg(sales)']
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
      
        [sum, (sum / pointers.length.to_f)]
      end
    
      cube.column_names.should include('sum(sales)')
      cube.column_names.should include('avg(sales)')
    
      sums = [
        27, 15, 18, 18, 6, 6, 12, 12, 9, 9, 9
      ]
    
      averages = [
        9, 7.5, 9, 9, 6, 6, 12, 12, 9, 9, 9
      ]
    
      cube.each_with_index do |row, index|
        row['sum(sales)'].should == sums[index]
        row['avg(sales)'].should == averages[index]
      end
    end
  
    it "should provide metadata about unique values for each dimension" do
      cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
      
        [sum, (sum / pointers.length.to_f)]
      end
    
      values = cube.values
      values['store'].should == ['S1', 'S2']
      values['product'].should == ['P1', 'P2']
      values['season'].should == ['f', 's']
    end
    
    it "should benchmark" do
      # data = []
      # 0.upto(45000) do |index|
      #   data << [(rand * 25).round, (rand * 25).round, (rand * 25).round, (rand * 5).round]
      # end
      # 
      # @table = Table.new(
      #   :column_names => [
      #     'location', 'product', 'time', 'sales'
      #   ], :data => data
      # )
      # 
      # @dimensions = ['location', 'product', 'time']
      # 
      # require 'benchmark'
      # 
      # cube = nil
      # puts Benchmark.measure {
      #   cube = QuotientCube.build(@table, @dimensions) do |table, pointers|
      #     5
      #   end
      # }
    end
  end
  
  describe "With the location, product, time data set" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'location', 'product', 'time', 'sales'
        ], :data => [
          ['Van', 'b', 'd1', 9],
          ['Van', 'f', 'd2', 3],
          ['Tor', 'b', 'd2', 6]
        ]
      )
  
      @dimensions = ['location', 'product', 'time']
      @measures = ['sales[sum]', 'sales[average]']
    end
    
    it "should build the temporary classes properly" do
      cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        
        [sum, sum / pointers.length]
      end
      
      cube.length.should == 13
    
      # this is absolutely correct, never change this again
    
      ids = [0, 12, 7, 6, 9, 1, 2, 4, 8, 11, 3, 5, 10]
          
      uppers = [
        ['*', '*', '*'], ['*', '*', 'd2'], ['*', 'b', '*'],
        ['Tor', 'b', 'd2'], ['Tor', 'b', 'd2'], ['Van', '*', '*'],
        ['Van', 'b', 'd1'], ['Van', 'b', 'd1'], ['Van', 'b', 'd1'],
        ['Van', 'b', 'd1'], ['Van', 'f', 'd2'], ['Van', 'f', 'd2'],
        ['Van', 'f', 'd2']
      ]
          
      lowers = [
        ['*', '*', '*'], ['*', '*', 'd2'],['*', 'b', '*'],
        ['Tor', '*', '*'], ['*', 'b', 'd2'], ['Van', '*', '*'],
        ['Van', 'b', '*'], ['Van', '*', 'd1'], ['*', 'b', 'd1'],
        ['*', '*', 'd1'], ['Van', 'f', '*'], ['Van', '*', 'd2'],
        ['*', 'f', '*']
      ]
          
      sales_sum = [18, 9, 15, 6, 6, 12, 9, 9, 9, 9, 3, 3, 3]
      sales_average = [6, 4, 7, 6, 6, 6, 9, 9, 9, 9, 3, 3, 3]
                
      uppers.zip(lowers).each_with_index do |pair, index|
        cube[index]['id'].should == ids[index]
        cube[index]['upper'].should == pair.first
        cube[index]['lower'].should == pair.last
        cube[index]['sales[sum]'].should == sales_sum[index]
        cube[index]['sales[average]'].should == sales_average[index]
      end
    end
  end
  
  describe "With randomly generated data" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'x1', 'x2', 'x3', 'x4', 'sales'
        ], :data =>   [
          [6, 3, 4, 5, 1], 
          [1, 9, 9, 1, 5], 
          [5, 7, 7, 8, 2],
          [7, 4, 9, 7, 4], 
          [2, 9, 10, 3, 0], 
          [1, 3, 7, 6, 5],
          [9, 0, 7, 4, 1], 
          [5, 6, 6, 6, 3], 
          [3, 4, 4, 1, 0],
          [9, 1, 2, 10, 4], 
          [6, 3, 6, 9, 4]
        ]
      ).sort(['x1', 'x2', 'x3', 'x4'])
  
      @dimensions, @measures = [
        'x1', 'x2', 'x3', 'x4',
      ], ['sales[sum]', 'sales[average]']
    end
    
    it "should generate the correct classes" do
      @cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
  
        [sum, (sum / pointers.length)]
      end
      
      uppers = [
        ['*', '*', '*', '*'], ["*", "*", 4, "*"], 
        ["*", "*", 6, "*"], [6, 3, "*", "*"]
      ]
      
      lowers = [
        ['*', '*', '*', '*'], ["*", "*", 4, "*"], 
        ["*", "*", 6, "*"], [6, "*", "*", "*"]
      ]
      
      sales_sums = [29, 1, 7, 5]      
      
      uppers.zip(lowers).each_with_index do |bounds, index|
        rows = @cube.where do |row| 
          row['upper'] = bounds.first and row['lower'] == bounds.last
        end
        
        rows.first['sales[sum]'].should == sales_sums[index]
      end
    end
  end
  
  describe "With a table that has extra dimensions" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'store', 'product', 'season', 'sales'
        ], :data => [
          ['S1', 'P1', 's', 6],
          ['S1', 'P2', 's', 12],
          ['S2', 'P1', 'f', 9]
        ]
      )
      
      @dimensions = ['store', 'season']
      @measures = ['sales']
    end
    
    it "should index correctly" do
      cube = QuotientCube::Base.new(@table, @dimensions, [])
      cube.indexes([0, 1, 2]).should == {
        'store' => {'S1' => [0, 1], 'S2' => [2]}, 
        'season' => {'f' => [2], 's' => [0, 1]}
      }
    end
    
    it "should generate the correct cube" do
      cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        sum / pointers.length.to_f      
      end
      
      cube.data.should == [
        [0, ['*', '*'], ['*', '*'], -1, 9.0],
        [1, ['S1', 's'], ['S1', '*'], 0, 9.0],
        [3, ['S1', 's'], ['*', 's'], 0, 9.0],
        [2, ['S2', 'f'], ['S2', '*'], 0, 9.0],
        [4, ['S2', 'f'], ['*', 'f'], 0, 9.0]
      ]
    end
  end
  
  describe "with a table that has fixed dimensions" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'hour', 'user[source]', 'user[age]', 'event[name]', 'user[id]'
        ], :data => [
          ['340023', 'blog', 'NULL', 'signup', '1'],
          ['340023', 'blog', 'NULL', 'signup', '2'],
          ['340023', 'twitter', '14', 'signup', '3']
        ]
      )
    
      @dimensions = ['hour', 'user[source]', 'user[age]', 'event[name]']
      @measures = ['events[count]', 'events[percentage]', 'users[count]', 'users[percentage]']
    
      total_events = @table.length
      total_users = @table.distinct('user[id]').length
      
      @cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        events_count = pointers.length
        events_percentage = (events_count / total_events.to_f) * 100
        
        users = Set.new
        pointers.each do |pointer|
          users << @table[pointer]['user[id]']
        end
        
        users_count = users.length
        users_percentage = (users_count / total_users.to_f) * 100
        
        [events_count, events_percentage, users_count, users_percentage]
      end
    end
    
    after(:each) do
      @database.close
    end
    
    it "should collapse fixed dimensions" do
      @cube.fixed.should == {'hour' => '340023', 'event[name]' => 'signup'}
      @cube.dimensions.should == ['user[source]', 'user[age]']
      
      uppers, lowers = [['*', '*'], ['blog', 'NULL'], 
        ['blog', 'NULL'], ['twitter', '14'], ['twitter', '14']], 
      [['*', '*'], ['blog', '*'], ['*', 'NULL'], 
        ['twitter', '*'], ['*', '14']]
      
      @cube.each_with_index do |row, index|
        row['upper'].should == uppers[index]
        row['lower'].should == lowers[index]
      end
    end
  end
end