require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe QuotientCube::Tree::Measure do
  before(:each) do
    @database = FakeTokyo::BDB.new 
    @tree = QuotientCube::Tree::Base.new(@database, :prefix => 'prefix')
    @node = QuotientCube::Tree::Node.create(@tree, 'root')
    @measure = QuotientCube::Tree::Measure.new('sales', 6.0)
  end
    
  it "should have a name and a value" do
    @measure.name.should == 'sales'
    @measure.value.should == 6.0
  end
end