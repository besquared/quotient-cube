require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Nodes do
  before(:each) do
    @tempfile = Tempfile.new('database')
    @database = TokyoCabinet::BDB.new
    @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)

    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
  end
  
  after(:each) do
    @database.close
  end
  
  it "should get root node" do
    @database.put("prefix:root", "1")
    
    root = @tree.nodes.root
    root.nil?.should == false
    root.id.should == '1'
    root.name.should == 'root'
  end
end