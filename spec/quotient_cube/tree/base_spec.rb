require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Base do
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

      @tree = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix').build
    end
    
    after(:each) do
      @database.close
    end
    
    it "should get a list of dimensions" do
      @tree.dimensions.should == ['store', 'product', 'season']
    end
    
    it "should get a list of measures" do
      @tree.measures.should == ['sales']
    end
    
    it "should get a list of values" do
      @tree.values('store').should == ['S1', 'S2']
      @tree.values('product').should == ['P1', 'P2']
      @tree.values('season').should == ['f', 's']
    end
  end
end