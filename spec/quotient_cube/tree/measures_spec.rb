require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Measures do
  before(:each) do
    @database = FakeTokyo::BDB.new 
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @measures = QuotientCube::Tree::Measures.new(@node)
  end
  
  it "should have key" do
    @measures.key.should == "prefix:1:measures"
  end
  
  it "should have database" do
    @measures.database.should == @database
  end
  
  it "should be empty" do
    @measures.empty?.should == true
  end
  
  it "should lazily instantiate no dimensions" do
    @measures.measures.should == []
  end

  it "should lazily instantiate one measures" do
    @database.putdup("prefix:1:measures", 'sales:6')
    
    measures = @measures.measures
    measures.length.should == 1
    measures.first.name.should == 'sales'
    measures.first.value.should == 6
  end
  
  it "should lazily instantiate two measures" do
    @database.putdup("prefix:1:measures", 'sales[sum]:6')
    @database.putdup("prefix:1:measures", 'sales[avg]:3')
    
    measures = @measures.measures
    measures.length.should == 2
    measures.first.name.should == 'sales[sum]'
    measures.first.value.should == 6
    measures.last.name.should == 'sales[avg]'
    measures.last.value.should == 3
  end
  
  it "should return nil if no measure is found" do
    @measures.find('fake').should == nil
  end
  
  it "should make a new measure" do
    measure = @measures.create('sales[avg]', 3)
    
    measure.name.should == 'sales[avg]'
    measure.value.should == 3
    @measures.length.should == 1
    @database.getlist('prefix:1:measures').should == ['sales[avg]:3']
  end
  
  it "should only create a measure if one doesn't exist" do
    measure = @measures.create('sales[avg]', 3)
    @database.getlist('prefix:1:measures').should == ['sales[avg]:3']
    
    measure = @measures.create('sales[avg]', 3)
    measure.name.should == 'sales[avg]'
    @database.getlist('prefix:1:measures').should == ['sales[avg]:3']
  end
end