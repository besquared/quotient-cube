require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Dimensions do
  before(:each) do
    @tempfile = Tempfile.new('database')
    @database = TokyoCabinet::BDB.new
    @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
    
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @dimensions = @node.dimensions
  end
  
  after(:each) do
    @database.close
  end
  
  it "should have key" do
    @dimensions.key.should == "prefix:1:dimensions"
  end
  
  it "should have database" do
    @dimensions.database.should == @database
  end
  
  it "should be empty" do
    @dimensions.empty?.should == true
  end
  
  it "should lazily instantiate no dimensions" do
    @dimensions.dimensions.should == []
  end
  
  it "should lazily instantiate some dimensions" do
    @database.putlist('prefix:1:dimensions', ['store', 'season'])
    dimensions = @dimensions.dimensions
    dimensions.length.should == 2
    dimensions.first.name.should == 'store'
    dimensions.second.name.should == 'season'
  end
  
  it "should return nil if no dimension is found" do
    @dimensions.find('fake').should == nil
  end
  
  it "should make a new dimension" do
    dimension = @dimensions.create('season')
    dimension.node.should == @node
    dimension.name.should == 'season'
    @dimensions.length.should == 1
    @database.getlist('prefix:1:dimensions').should == ['season']
  end
  
  it "should only create a dimension if one doesn't exist" do
    dimension = @dimensions.create('season')
    @database.getlist('prefix:1:dimensions').should == ['season']
    
    dimension = @dimensions.create('season')
    dimension.name.should == 'season'
    @database.getlist('prefix:1:dimensions').should == ['season']
  end
end