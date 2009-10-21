require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include TokyoCabinet

describe QuotientCube::Tree::Builder do
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

      @builder = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix')
    end
    
    after(:each) do
      @database.close
    end
    
    it "should build meta" do
      @builder.build_meta
      @database.getlist('prefix:dimensions').should == ['store', 'product', 'season']
      @database.getlist('prefix:measures').should == ['sales']
      @database.getlist('prefix:[store]').should == ['S1', 'S2']
      @database.getlist('prefix:[product]').should == ['P1', 'P2']
      @database.getlist('prefix:[season]').should == ['f', 's']
    end
    
    it "should build root" do
      @builder.build_root
      @database.get('prefix:root').should == '1'
      @database.getlist('prefix:1:measures').should == ['sales:9.0']
    end
    
    it "should build nodes" do
      @builder.build_root
      @builder.build_nodes(['S1', 'P1', 's'], {'sales' => 6.0})
      
      @database.getlist('prefix:1:dimensions').should == ['store']
      @database.getlist('prefix:1:[store]').should == ['2:S1']
      @database.getlist('prefix:2:dimensions').should == ['product']
      @database.getlist('prefix:2:[product]').should == ['3:P1']
      @database.getlist('prefix:3:dimensions').should == ['season']
      @database.getlist('prefix:3:[season]').should == ['4:s']
      @database.getlist('prefix:4:measures').should == ['sales:6.0']
    end
    
    it "should build link" do
      @builder.build_root
      
      destination = @builder.build_nodes(['S1', 'P1', 's'], {'sales' => 6.0})
      source = @builder.build_nodes(['*', 'P1', '*'], {'sales' => 7.5})
      
      @builder.build_link(source.compact.last, destination.last, 'season')
      
      @database.getlist('prefix:5:dimensions').should == ['season']
      @database.getlist('prefix:5:[season]').should == ['4:s']
    end
    
    it "should build quotient cube tree" do
      @builder.build
      
      @database.get("prefix:last_id").unpack("i").first.should == 11
      @database.getlist("prefix:dimensions").should == ["store", "product", "season"]
      @database.getlist("prefix:measures").should == ["sales"]
      @database.get("prefix:root").should == "1"
      @database.getlist("prefix:[store]").should == ["S1", "S2"]
      @database.getlist("prefix:[product]").should == ["P1", "P2"]
      @database.getlist("prefix:[season]").should == ["f", "s"]

      @database.getlist("prefix:1:dimensions").should == ["product", "store", "season"]
      @database.getlist("prefix:1:measures").should == ["sales:9.0"]
      @database.getlist("prefix:1:[store]").should == ["3:S1", "9:S2"]
      @database.getlist("prefix:1:[product]").should == ["2:P1", "7:P2"]
      @database.getlist("prefix:1:[season]").should == ["4:s", "11:f"]

      @database.getlist("prefix:2:dimensions").should == ["season"]
      @database.getlist("prefix:2:measures").should == ["sales:7.5"]
      @database.getlist("prefix:2:[season]").should == ["6:s", "11:f"]

      @database.getlist("prefix:3:dimensions").should == ["season", "product"]
      @database.getlist("prefix:3:[season]").should == ["4:s"]
      @database.getlist("prefix:3:[product]").should == ["5:P1", "7:P2"]

      @database.getlist("prefix:4:measures").should == ["sales:9.0"]

      @database.getlist("prefix:5:dimensions").should == ["season"]
      @database.getlist("prefix:5:[season]").should == ["6:s"]

      @database.getlist("prefix:6:measures").should == ["sales:6.0"]

      @database.getlist("prefix:7:dimensions").should == ["season"]
      @database.getlist("prefix:7:[season]").should == ["8:s"]

      @database.getlist("prefix:8:measures").should == ["sales:12.0"]

      @database.getlist("prefix:9:dimensions").should == ["product"]
      @database.getlist("prefix:9:[product]").should == ["10:P1"]

      @database.getlist("prefix:10:dimensions").should == ["season"]
      @database.getlist("prefix:10:[season]").should == ["11:f"]

      @database.getlist("prefix:11:measures").should == ["sales:9.0"]
    end
    
    it "should be able to put more than one tree into a single database" do
      @builder.build
      
      @database.close
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
      
      @builder = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix2')
      
      @builder.build
      
      @database.fwmkeys('prefix:').length.should == 30
      @database.fwmkeys('prefix2:').length.should == 30
    end
  end
end