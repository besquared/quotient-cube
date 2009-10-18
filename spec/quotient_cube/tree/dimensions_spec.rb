require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Dimensions do
  before(:each) do
    @database = FakeTokyo::BDB.new 
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @dimensions = @node.dimensions
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
    @database.should_receive(:get).with("prefix:1:dimensions").and_return([])
    @dimensions.dimensions.should == []
  end
  
  it "should lazily instantiate one dimension" do
    @database.should_receive(:get).with("prefix:1:dimensions").and_return('season')
    dimensions = @dimensions.dimensions
    dimensions.length.should == 1
    dimensions.first.name.should == 'season'
  end
  
  it "should lazily instantiate two dimensions" do
    @database.should_receive(:get).with("prefix:1:dimensions").and_return(['season', 'store'])
    dimensions = @dimensions.dimensions
    dimensions.length.should == 2
    dimensions.first.name.should == 'season'
    dimensions.second.name.should == 'store'
  end
  
  it "should return nil if no dimension is found" do
    @dimensions.find('fake').should == nil
  end
  
  it "should make a new dimension" do
    dimension = @dimensions.create('season')
    dimension.node.should == @node
    dimension.name.should == 'season'
    @dimensions.length.should == 1
    @database.get('prefix:1:dimensions').should == 'season'
  end
  
  it "should only create a dimension if one doesn't exist" do
    dimension = @dimensions.create('season')
    @database.get('prefix:1:dimensions').should == 'season'
    
    dimension = @dimensions.create('season')
    dimension.name.should == 'season'
    @database.get('prefix:1:dimensions').should == 'season'
  end
end