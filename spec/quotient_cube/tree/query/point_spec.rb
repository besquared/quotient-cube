require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

describe QuotientCube::Tree::Query::Point do
  describe "With store, product and season dataset" do
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
  
      @dimensions, @measures = ['store', 'product', 'season'], ['sales']
  
      @cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        sum / pointers.length.to_f
      end
    
      @tempfile = Tempfile.new('database')
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
      
      QuotientCube::Tree::Builder.debug do
        @tree = QuotientCube::Tree::Builder.build(@database, @cube, :prefix => 'prefix')
      end
    end
    
    after(:each) do
      @database.close
    end
    #   
    # it "should answer with empty conditions" do
    #   answer = QuotientCube::Tree::Query::Point.new(@tree, {}, ['sales']).process
    #   answer.should == {'sales' => 9}
    # end
    
    it "should answer a variety of conditions" do
      QuotientCube::Tree::Query::Point.new(
        @tree, {'store' => 'S2', 'season' => 's'}, ['sales']
      ).process.should == nil
      
      QuotientCube::Tree::Query::Point.new(
        @tree, {'store' => 'S2', 'season' => 'f'}, ['sales']
      ).process.should == {'sales' => 9}
    
      QuotientCube::Tree::Query::Point.new(
        @tree, {'product' => 'P1'}, ['sales']
      ).process.should == {'sales' => 7.5}

      QuotientCube::Tree::Query::Point.new(
        @tree, {'product' => 'P2'}, ['sales']
      ).process.should == {'sales' => 12}
      
      QuotientCube::Tree::Query::Base.debug do
      QuotientCube::Tree::Query::Point.new(
        @tree, {'store' => 'S1'}, ['sales']
      ).process.should == {'sales' => 9}
      end
      
      QuotientCube::Tree::Query::Point.new(
        @tree, {'store' => 'S1', 'product' => 'P1'}, ['sales']
      ).process.should == {'sales' => 6}
    end
    
    # it "should benchmark" do
    #   query = QuotientCube::Tree::Query::Point.new(
    #     @tree, {'store' => 'S2', 'season' => 's'}, ['sales']
    #   )
    #   
    #   Benchmark.bm do |bench|
    #     bench.report { 3500.times { query.process } }
    #   end
    # end
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
      
      @cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        
        [sum, (sum / pointers.length)]
      end
    end
  end
  
  describe "With a made up dataset" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'country', 'state', 'city', 'store', 'sales'
        ], :data =>   [
          ['US', 'CA', 'San Francisco', 'A', 5], 
          ['US', 'WA', 'Seattle', 'B', 5],
          ['CA', 'BC', 'Vancouver', 'C', 2]
        ]
      ).sort(['country', 'state', 'city', 'store'])

      dimensions, measures = [
       'country', 'state', 'city', 'store',
      ], ['sales[sum]', 'sales[average]']

      @cube = QuotientCube::Base.build(
        @table, dimensions, measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
                
        [sum, (sum / pointers.length.to_f)]
      end
      
      @tempfile = Tempfile.new('database')
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)

      @tree = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix').build      
    end
    
    after(:each) do
      @database.close
    end
    
    it "should answer with empty conditions" do
      QuotientCube::Tree::Query::Point.new(
        @tree, {}, ['sales[sum]', 'sales[average]']
      ).process.should == {'sales[sum]' => 12, 'sales[average]' => 4}
    end
    
    it "should answer query with a variety of conditions" do
      QuotientCube::Tree::Query::Point.new(
        @tree, {'country' => 'UK'}, ['sales[sum]']
      ).process.should == nil

      QuotientCube::Tree::Query::Point.new(
        @tree, {'country' => 'US'}, ['sales[sum]']
      ).process.should == {'sales[sum]' => 10}
      
      QuotientCube::Tree::Query::Point.new(
        @tree, {'state' => 'WA'}, ['sales[sum]']
      ).process.should == {'sales[sum]' => 5}
      
      QuotientCube::Tree::Query::Point.new(
        @tree, {'country' => 'US', 'state' => 'WA'}, ['sales[sum]']
      ).process.should == {'sales[sum]' => 5}
      
      QuotientCube::Tree::Query::Point.new(
        @tree, {'country' => 'US', 'state' => 'BC'}, ['sales[sum]']
      ).process.should == nil
    end
  end
end