require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

describe QuotientCube::Tree::Query::Range do
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

      @tree = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix').build
    end
    
    after(:each) do
      @database.close
    end
    
    it "should answer with empty conditions" do
      QuotientCube::Tree::Query::Range.new(
        @tree, {'store' => '*', 'product' => '*', 'season' => '*'}, ['sales']
      ).process.should == [{'sales' => 9}]
    end
    
    it "should answer with a variety of conditions" do
      QuotientCube::Tree::Query::Range.new(@tree, {
        'store' => ['S1', 'S2', 'S3'], 
        'product' => ['P1', 'P3'], 'season' => 'f'
      }, ['sales']).process.should == [{
        'store' => 'S2', 'product' => 'P1', 'season' => 'f', 'sales' => 9
      }]

      QuotientCube::Tree::Query::Range.new(@tree, {
        'store' => ['S1', 'S2', 'S3'],  
        'product' => ['P1', 'P2'], 'season' => '*'
      }, ['sales']).process.should == [
        {'store' => 'S1', 'product' => 'P1', 'sales' => 6},
        {'store' => 'S1', 'product' => 'P2', 'sales' => 12},
        {'store' => 'S2', 'product' => 'P1', 'sales' => 9}
      ]

      QuotientCube::Tree::Query::Range.new(@tree, {
        'store' => '*',  'product' => '*', 'season' => ['f', 's']
      }, ['sales']).process.should ==   [
        {'season' => 'f', 'sales' => 9},
        {'season' => 's', 'sales' => 9}
      ]
      
      QuotientCube::Tree::Query::Range.new(@tree, {
        'store' => '*',  'product' => ['P1', 'P2'], 'season' => '*'
      }, ['sales']).process.should ==   [
        {'product' => 'P1', 'sales' => 7.5},
        {'product' => 'P2', 'sales' => 12}
      ]
    end
    
    # it "should benchmark" do
    #   puts Benchmark.measure {
    #     1000.times {
    #       QuotientCube::Tree::Query::Range.new(@tree, {
    #         'store' => ['S1', 'S2', 'S3'], 
    #         'product' => ['P1', 'P3'], 'season' => 'f'
    #       }, ['sales']).process.should == [{
    #         'store' => 'S2', 'product' => 'P1', 'season' => 'f', 'sales' => 9
    #       }]
    #     }
    #   }
    # end
  end
end