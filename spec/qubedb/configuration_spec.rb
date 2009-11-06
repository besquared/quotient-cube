require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Qubedb::Configuration do
  before(:each) do
    Qubedb::Configuration.configure(:data_path => 'mydata', :temp_path => 'mytmp')
  end
  
  it "should have the proper temp path" do
    Qubedb::Configuration.data_path.should == File.expand_path('mydata')
  end
  
  it "should have the correct temp path" do
    Qubedb::Configuration.temp_path.should == File.expand_path('mytmp')
  end
end