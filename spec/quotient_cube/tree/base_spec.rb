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
    end
    
    # it "should write quotient cube to storage" do
    #   database = FakeTokyo::BDB.new
    #   QuotientCube::Tree::Base.store2(database, @cube, :prefix => 'prefix')
    #   
    #   puts database.inspect
    # end
  
  #   it "should store to a key-value database" do
  #     database = FakeTokyo::HDB.new
  #     QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #   
  #     verify_key(database, 'hour:span:meta[dimensions]', @dimensions)
  #     verify_key(database, 'hour:span:root', {'dimensions' => @dimensions, 'measures' => {'sales' => 9}})
  #     verify_key(database, 'hour:span:root[store]', {'S1' => nil, 'S2' => nil})
  #     verify_key(database, 'hour:span:root[product]', {'P1' => nil, 'P2' => 'hour:span:root:[store=S1]:[product=P2]'})
  #     verify_key(database, 'hour:span:root[season]', {'s' => 'hour:span:root:[store=S1]:[season=s]', 'f' => 'hour:span:root:[store=S2]:[product=P1]:[season=f]'})
  #     verify_key(database, 'hour:span:root:[store=S1]', {'dimensions' => [nil, 'product', 'season']})
  #     verify_key(database, 'hour:span:root:[store=S1][season]', {'s' => nil})
  #     verify_key(database, 'hour:span:root:[store=S1][product]', {'P1' => nil, 'P2' => nil})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P1]', {'dimensions' => [nil, nil, 'season']})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P1][season]', {'s' => nil})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P1]:[season=s]', {'measures' => {'sales' => 6}})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P2]', {'dimensions' => [nil, nil, 'season']})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P2][season]', {'s' => nil})
  #     verify_key(database, 'hour:span:root:[store=S1]:[product=P2]:[season=s]', {'measures' => {'sales' => 12}})
  #     verify_key(database, 'hour:span:root:[store=S2]', {'dimensions' => [nil, 'product', nil]})
  #     verify_key(database, 'hour:span:root:[store=S2][product]', {'P1' => nil})
  #     verify_key(database, 'hour:span:root:[store=S2]:[product=P1]', {'dimensions' => [nil, nil, 'season']})
  #     verify_key(database, 'hour:span:root:[store=S2]:[product=P1][season]', {'f' => nil})
  #     verify_key(database, 'hour:span:root:[store=S2]:[product=P1]:[season=f]', {'measures' => {'sales' => 9}})
  #     verify_key(database, 'hour:span:root:[product=P1]', {'measures' => {'sales' => 7.5}, 'dimensions' => [nil, nil, 'season']})
  #     verify_key(database, 'hour:span:root:[product=P1][season]', {'s' => 'hour:span:root:[store=S1]:[product=P1]:[season=s]', 'f' => 'hour:span:root:[store=S2]:[product=P1]:[season=f]'})
  #   end
  # 
  #   it "should query meta data" do
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #     tree.meta_query('dimensions').should == @dimensions
  #     tree.meta_query('measures').should == @measures
  #     tree.meta_query('values[store]').should == ['S1', 'S2']
  #     tree.meta_query('values[product]').should == ['P1', 'P2']
  #     tree.meta_query('values[season]').should == ['f', 's']
  #   end
  # 
  #   it "should query with point conditions" do
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #     # puts Benchmark.measure {
  #       # 10000.times do
  #         tree.query(['sales'], {'store' => 'S2', 'season' => 'f'}).should == {'sales' => 9}
  #       # end
  #     # }
  #     tree.query(['sales'], {'store' => 'S2', 'season' => 's'}).should == nil
  #     tree.query(['sales'], {'product' => 'P2'}).should == {'sales' => 12}
  #     tree.query(['sales'], {'product' => 'P1'}).should == {'sales' => 7.5}
  #     tree.query(['sales'], {'store' => 'S1'}).should == {'sales' => 9}
  #     tree.query(['sales'], {'season' => 's'}).should == {'sales' => 9}
  #     tree.query(['sales'], {}).should == {'sales' => 9}
  #     tree.query(['sales'], {'store' => 'S2', 'product' => 'P1', 'season' => 'f'}).should == {'sales' => 9}
  #   end
  # 
  #   it "should query with point and range conditions" do
  #     pending 
  #     
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #   
  #     tree.query(['sales'], {
  #       'store' => ['S1', 'S2', 'S3'], 
  #       'product' => ['P1', 'P3'], 'season' => 'f'
  #     }).should == [{'store' => 'S2', 'product' => 'P1', 'season' => 'f', 'sales' => 9}]
  #     
  #     tree.query(['sales'], {
  #       'store' => ['S1', 'S2', 'S3'], 
  #       'product' => ['P1', 'P2'], 'season' => 'f'
  #     }).should == [{'store' => 'S2', 'product' => 'P1', 'season' => 'f', 'sales' => 9}]
  #     
  #     tree.query(['sales'], {
  #       'store' => ['S1', 'S2', 'S3'], 'product' => ['P1', 'P2']
  #     }).should == [
  #       {'store' => 'S1', 'product' => 'P1', 'sales' => 6},
  #       {'store' => 'S1', 'product' => 'P2', 'sales' => 12},
  #       {'store' => 'S2', 'product' => 'P1', 'sales' => 9}
  #     ]
  #     
  #     tree.query(['sales'], {'season' => :all}).should == [
  #       {'season' => 'f', 'sales' => 9},
  #       {'season' => 's', 'sales' => 9}
  #     ]
  #     
  #     tree.query(['sales'], {'product' => :all}).should == [
  #       {'product' => 'P1', 'sales' => 7.5},
  #       {'product' => 'P2', 'sales' => 12}
  #     ]
  #   end
  # 
  #   it "should be representable as a DOT file" do
  #     pending 
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #   
  #     # File.open('database.dot', 'w+'){|f| f.write(tree.to_dot)}
  #   end
  # 
  #   it "should benchmark" do
  #     # data = []
  #     # 0.upto(100_000) do |index|
  #     #   data << [(rand * 100).round, (rand * 100).round, (rand * 100).round, (rand * 100).round, (rand * 100).round, (rand * 100).round, (rand * 5).round]
  #     # end
  #     # 
  #     # @table = Table.new(
  #     #   :column_names => [
  #     #     'location', 'product', 'time', 'sales'
  #     #   ], :data => data
  #     # )
  #     # 
  #     # @dimensions = ['location', 'product', 'time']
  #     # @measures = ['sales']
  #     # 
  #     # require 'benchmark'
  #     # 
  #     # cube = QuotientCube::Base.build(@table, @dimensions, @measures) do |table, pointers|
  #     #   5
  #     # end
  #     # 
  #     # database = FakeTokyo::HDB.new
  #     # database = TokyoCabinet::HDB.new
  #     # 
  #     # database.open('database.tch', TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT)
  #     # 
  #     # puts Benchmark.measure {
  #     #   QuotientCube::Tree::Base.store(database, cube, :prefix => 'hour:span')
  #     # }
  #     # 
  #     # database.close
  #   end
  # end
  # 
  # describe "With the location, product, time data set" do
  #   before(:each) do
  #     @table = Table.new(
  #       :column_names => [
  #         'location', 'product', 'time', 'sales'
  #       ], :data => [
  #         ['Van', 'b', 'd1', 9],
  #         ['Van', 'f', 'd2', 3],
  #         ['Tor', 'b', 'd2', 6]
  #       ]
  #     )
  # 
  #     @dimensions = ['location', 'product', 'time']
  #     @measures = ['sales[sum]', 'sales[average]']
  #     
  #     @cube = QuotientCube::Base.build(
  #       @table, @dimensions, @measures
  #     ) do |table, pointers|
  #       sum = 0
  #       pointers.each do |pointer|
  #         sum += table[pointer]['sales']
  #       end
  #       
  #       [sum, (sum / pointers.length)]
  #     end
  #   end
  #   
  #   it "should query with point conditions" do
  #     pending
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #     
  #     tree.query(['sales[sum]'], {'location' => 'Van'}).should == {'sales[sum]' => 12}
  #     tree.query(['sales[sum]'], {'location' => 'Van', 'time' => 'd2'}).should == {'sales[sum]' => 3}
  #     tree.query(['sales[sum]'], {'location' => 'Van', 'product' => 'b'}).should == {'sales[sum]' => 9}
  #     tree.query(['sales[sum]'], {'product' => 'b'}).should == {'sales[sum]' => 15}
  #     tree.query(['sales[sum]', 'sales[average]'], {'time' => 'd2'}).should == {'sales[sum]' => 9, 'sales[average]' => 4}
  #   end
  #   
  #   it "should query with point and range conditions" do
  #     pending
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #     
  #     # File.open('database.dot', 'w+'){|f| f.write(tree.to_dot)}
  #     
  #     tree.query(['sales[sum]'], {
  #       'location' => ['Van', 'Tor', 'SF'], 
  #       'product' => ['b', 'x', 'y'], 'time' => 'd2'
  #     }).should == [
  #       {'location' => 'Tor', 'product' => 'b', 'time' => 'd2', 'sales[sum]' => 6}
  #     ]
  #     
  #     tree.query(['sales[sum]'], {'time' => ['d1', 'd2']}).should == [
  #       {'time' => 'd1', 'sales[sum]' => 9},
  #       {'time' => 'd2', 'sales[sum]' => 9}
  #     ]
  #     
  #     tree.query(['sales[sum]'], {'product' => ['b', 'f']}).should == [
  #       {'product' => 'b', 'sales[sum]' => 15},
  #       {'product' => 'f', 'sales[sum]' => 3}
  #     ]
  #     
  #     tree.query(['sales[sum]'], {'location' => :all}).should == [
  #       {'location' => 'Tor', 'sales[sum]' => 6},
  #       {'location' => 'Van', 'sales[sum]' => 12}
  #     ]
  #     
  #     tree.query(['sales[sum]'], {'location' => :all, 'product' => :all}).should == [
  #       {'location' => 'Tor', 'product' => 'b', 'sales[sum]' => 6},
  #       {'location' => 'Van', 'product' => 'b', 'sales[sum]' => 9},
  #       {'location' => 'Van', 'product' => 'f', 'sales[sum]' => 3}
  #     ]
  #   end
  #   
  #   it "should expand :all for measures to all measures" do
  #     pending
  #     database = FakeTokyo::HDB.new
  #     tree = QuotientCube::Tree::Base.store(database, @cube, :prefix => 'hour:span')
  #     
  #     tree.query(:all, {
  #       'location' => ['Van', 'Tor', 'SF'], 
  #       'product' => ['b', 'x', 'y'], 'time' => 'd2'
  #     }).should == [
  #       {'location' => 'Tor', 'product' => 'b', 'time' => 'd2', 'sales[sum]' => 6, 'sales[average]' => 6}
  #     ]
  #   end
  end  
end