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
      @database.getlist('prefix:1:measures').should == ['sales']
      @database.get('prefix:1:{sales}').should == '9.0'
    end
    
    it "should build nodes" do
      @builder.build_root
      @builder.build_nodes(['S1', 'P1', 's'], {'sales' => 6.0})
      
      @database.getlist('prefix:1:dimensions').should == ['store']
      @database.getlist('prefix:1:[store]').should == ['S1']
      @database.get('prefix:1:[store]:S1').should == '2'
      @database.getlist('prefix:2:dimensions').should == ['product']
      @database.getlist('prefix:2:[product]').should == ['P1']
      @database.get('prefix:2:[product]:P1').should == '3'
      @database.getlist('prefix:3:dimensions').should == ['season']
      @database.getlist('prefix:3:[season]').should == ['s']
      @database.get('prefix:3:[season]:s').should == '4'
      @database.getlist('prefix:4:measures').should == ['sales']
      @database.get('prefix:4:{sales}').should == '6.0'
    end
    
    it "should build link" do
      @builder.build_root
      
      destination = @builder.build_nodes(['S1', 'P1', 's'], {'sales' => 6.0})
      source = @builder.build_nodes(['*', 'P1', '*'], {'sales' => 7.5})
      
      @builder.build_link(source.compact.last, destination.last, 's', 'season')
      
      @database.getlist('prefix:5:dimensions').should == ['season']
      @database.getlist('prefix:5:[season]').should == ['s']
      @database.get('prefix:5:[season]:s').should == '4'
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
      @database.getlist("prefix:1:measures").should == ["sales"]
      @database.get("prefix:1:{sales}").should == '9.0'
      @database.getlist("prefix:1:[store]").should == ["S1", "S2"]
      @database.get("prefix:1:[store]:S1").should == '3'
      @database.get("prefix:1:[store]:S2").should == '9'
      @database.getlist("prefix:1:[product]").should == ["P1", "P2"]
      @database.get('prefix:1:[product]:P1').should == '2'
      @database.get('prefix:1:[product]:P2').should == '7'
      @database.getlist("prefix:1:[season]").should == ["s", "f"]
      @database.get('prefix:1:[season]:s').should == '4'
      @database.get('prefix:1:[season]:f').should == '11'

      @database.getlist("prefix:2:dimensions").should == ["season"]
      @database.getlist("prefix:2:measures").should == ["sales"]
      @database.get("prefix:2:{sales}").should == "7.5"
      @database.getlist("prefix:2:[season]").should == ["s", "f"]
      @database.get("prefix:2:[season]:s").should == '6'
      @database.get("prefix:2:[season]:f").should == '11'

      @database.getlist("prefix:3:dimensions").should == ["season", "product"]
      @database.getlist("prefix:3:[season]").should == ["s"]
      @database.get("prefix:3:[season]:s").should == '4'
      @database.getlist("prefix:3:[product]").should == ["P1", "P2"]
      @database.get("prefix:3:[product]:P1").should == '5'
      @database.get("prefix:3:[product]:P2").should == '7'

      @database.getlist("prefix:4:measures").should == ["sales"]
      @database.get("prefix:4:{sales}").should == '9.0'

      @database.getlist("prefix:5:dimensions").should == ["season"]
      @database.getlist("prefix:5:[season]").should == ["s"]
      @database.get("prefix:5:[season]:s").should == '6'

      @database.getlist("prefix:6:measures").should == ["sales"]
      @database.get("prefix:6:{sales}").should == '6.0'

      @database.getlist("prefix:7:dimensions").should == ["season"]
      @database.getlist("prefix:7:[season]").should == ["s"]
      @database.get("prefix:7:[season]:s").should == '8'

      @database.getlist("prefix:8:measures").should == ["sales"]
      @database.get('prefix:8:{sales}').should == '12.0'

      @database.getlist("prefix:9:dimensions").should == ["product"]
      @database.getlist("prefix:9:[product]").should == ["P1"]
      @database.get("prefix:9:[product]:P1").should == '10'

      @database.getlist("prefix:10:dimensions").should == ["season"]
      @database.getlist("prefix:10:[season]").should == ["f"]
      @database.get("prefix:10:[season]:f").should == '11'

      @database.getlist("prefix:11:measures").should == ["sales"]
      @database.get("prefix:11:{sales}").should == '9.0'
    end
    
    it "should be able to put more than one tree into a single database" do
      @builder.build
      
      @database.close
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
      
      @builder = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix2')
      
      @builder.build
      
      @database.fwmkeys('prefix:').length.should == 51
      @database.fwmkeys('prefix2:').length.should == 51
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
      
      @tempfile = Tempfile.new('database')
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
      @builder = QuotientCube::Tree::Builder.new(@database, @cube, :prefix => 'prefix')
    end
    
    after(:each) do
      @database.close
    end
    
    it "should build meta" do
      @builder.build_meta
      @database.getlist('prefix:dimensions').should == ['user[source]', 'user[age]']
      @database.getlist('prefix:fixed').should == ['hour:340023', 'event[name]:signup']
      @database.getlist('prefix:measures').should == ['events[count]', 'events[percentage]', 'users[count]', 'users[percentage]']
      @database.getlist('prefix:[user[source]]').should == ['blog', 'twitter']
      @database.getlist('prefix:[user[age]]').should == ['14', 'NULL']
    end
  end
end