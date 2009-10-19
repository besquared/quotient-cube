require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Children do
  before(:each) do
    @tempfile = Tempfile.new('database')
    @database = TokyoCabinet::BDB.new
    @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)

    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @dimension = QuotientCube::Tree::Dimension.new(@node, 'store')
    @children = @dimension.children
  end
  
  after(:each) do
    @database.close
  end
  
  it "should have database" do
    @children.database.should == @database
  end
  
  it "should be empty" do
    @children.empty?.should == true
  end
  
  it "should lazily instantiate no children" do
    @children.children.should == []
  end
  
  it "should lazily instantiate one child" do
    @database.putdup("prefix:1:[store]", '2:S1')
    @children.children.length.should == 1
    @children.children.first.id.should == '2'
    @children.children.first.name.should == 'S1'
  end
  
  it "should lazily instantiate two children" do
    @database.putlist("prefix:1:[store]", ["2:S1", "3:S2"])
    @children.children.length.should == 2
    @children.children.first.id.should == '2'
    @children.children.first.name.should == 'S1'
    @children.children.last.id.should == '3'
    @children.children.last.name.should == 'S2'
  end
  
  it "should return nil if no dimension is found" do
    @children.find('fake').should == nil
  end
  
  it "should make a new child node" do
    child = @children.create('S1')
    child.tree.should == @tree
    child.name.should == 'S1'
    @children.length.should == 1
    @database.getlist('prefix:1:[store]').should == ['2:S1']
  end
  
  it "should only create a child if one doesn't exist" do
    s1 = @children.create('S1')
    @database.getlist('prefix:1:[store]').should == ['2:S1']
    
    child = @children.create('S1')
    child.name.should == 'S1'
    @database.getlist('prefix:1:[store]').should == ['2:S1']
  end
  
  it "should add node without creating it" do
    node = QuotientCube::Tree::Node.create(@tree, 'S2')
    @children.add(node)
    @database.getlist('prefix:1:[store]').should == ['2:S2']
  end
end