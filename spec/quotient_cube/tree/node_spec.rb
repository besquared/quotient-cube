require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Node do
  before(:each) do
    @tempfile = Tempfile.new('database')
    @database = TokyoCabinet::BDB.new
    @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)

    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
  end
  
  after(:each) do
    @database.close
  end
  
  it "should generate a new id" do
    QuotientCube::Tree::Node.generate_id(@tree).should == 2
    @tree.database.get("#{@tree.prefix}last_id").unpack('i').first.should == 2
  end
  
  it "should have an id, name, dimensions, measures and database" do
    @node.id.should == 1
    @node.name.should == 'root'
    @node.dimensions.should_not == nil
    @node.measures.should_not == nil
    @node.database.should == @tree.database
  end
end