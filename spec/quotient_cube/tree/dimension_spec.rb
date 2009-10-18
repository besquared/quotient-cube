require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Dimension do
  before(:each) do
    @database = FakeTokyo::BDB.new 
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @dimension = QuotientCube::Tree::Dimension.new(@node, 'season')
  end
  
  it "should have an node, name, children and database" do
    @dimension.node.should == @node
    @dimension.name.should == 'season'
    @dimension.children.should_not == nil
    @dimension.database.should == @database
  end
end