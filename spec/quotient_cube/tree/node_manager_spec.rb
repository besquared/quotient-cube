require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

include TokyoCabinet

describe QuotientCube::Tree::NodeManager do
  before(:each) do
    @tempfile = Tempfile.new('database')
    @database = TokyoCabinet::BDB.new
    @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)
    
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    
    @root = @tree.nodes.create_root
  end
  
  it "should not find a root node" do
    @root.should == 1
  end
  
  it "should not create a root node if it exists" do
    @tree.nodes.create_root.should == '1'
    @tree.nodes.root.should == '1'
  end
  
  it "should create a node" do
    @tree.nodes.create.should == 2
  end
  
  it "should not find dimensions" do
    @tree.nodes.dimensions(@root).should == []
  end
  
  it "should create and find dimensions" do
    @tree.nodes.add_dimension(@root, 'store').should == 'store'
    @tree.nodes.dimensions(@root).should == ['store']
  end
  
  it "should not create a dimension on a node if it exists" do
    @tree.nodes.add_dimension(@root, 'store').should == 'store'
    @tree.nodes.add_dimension(@root, 'store').should == 'store'
    @tree.nodes.dimensions(@root).should == ['store']
  end
  
  it "should not find children" do
    @tree.nodes.add_dimension(@root, 'store')
    @tree.nodes.children(@root, 'store').should == []
  end
  
  it "should create and find children" do
    @tree.nodes.add_dimension(@root, 'store')
    @tree.nodes.add_child(@root, 'store', 'S1').should == 2
    @tree.nodes.add_child(@root, 'store', 'S2').should == 3
    @tree.nodes.children(@root, 'store').should == ['S1', 'S2']
    @tree.nodes.child(@root, 'store', 'S1').should == '2'
    @tree.nodes.child(@root, 'store', 'S2').should == '3'
  end
  
  it "should not create a new child if one exists" do
    @tree.nodes.add_dimension(@root, 'store')
    @tree.nodes.add_child(@root, 'store', 'S1').should == 2
    @tree.nodes.add_child(@root, 'store', 'S1').should == '2'
    @tree.nodes.children(@root, 'store').should == ['S1']
    @tree.nodes.child(@root, 'store', 'S1').should == '2'
  end
  
  it "should not find any measures" do
    @tree.nodes.measures(@root).should == []
  end
  
  it "should create and find measures" do
    @tree.nodes.add_measure(@root, 'event[count]', 2).should == 2
    @tree.nodes.measures(@root).should == ['event[count]']
    @tree.nodes.measure(@root, 'event[count]').to_i.should == 2
  end
  
  it "should not createa a  measure if it exists" do
    @tree.nodes.add_measure(@root, 'event[count]', 2).should == 2
    @tree.nodes.add_measure(@root, 'event[count]', 3).should == 2.0
    @tree.nodes.measures(@root).should == ['event[count]']
    @tree.nodes.measure(@root, 'event[count]').to_i.should == 2
  end
  
  it "should store float measures" do
    @tree.nodes.add_measure(@root, 'event[count]', 4.5).should == 4.5
  end
end