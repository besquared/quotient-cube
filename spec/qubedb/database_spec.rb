require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Qubedb::Database do
  before(:each) do
    Qubedb::Configuration.configure(:data_path => 'data')
    @database = Qubedb::Database.new('socialytical')
  end
  
  it "should have the correct path" do
    @database.path.should == File.expand_path('data') + '/socialytical'
  end
  
  it "should have the correct tables path" do
    @database.tables_path.should == File.expand_path('data') + '/socialytical/tables'
  end
  
  it "should write the correct tables path" do
    path = File.expand_path('data') + '/socialytical/tables'
    
    FakeFS do
      Qubedb::Database.write_tables_path('socialytical').to_s.should == path
      File.exist?(path).should == true
    end
  end
  
  it "should write the correct cubes path" do
    path = File.expand_path('data') + '/socialytical/cubes'
    
    FakeFS do
      Qubedb::Database.write_cubes_path('socialytical').to_s.should == path
      File.exist?(path).should == true
    end
  end
  
  it "should have the correct cubes path" do
    @database.cubes_path.should == File.expand_path('data') + '/socialytical/cubes'
  end
  
  it "should have tables" do
    @database.tables.should_not == nil
  end
  
  it "should have cubes" do
    @database.cubes.should_not == nil
  end
  
  it "should create a database" do
    base_path = File.expand_path('data') + '/socialytical'
    tables_path = File.join(base_path, 'tables')
    cubes_path = File.join(base_path, 'cubes')
    
    FakeFS do
      database = Qubedb::Database.create('socialytical')
      database.path.to_s.should == base_path
    
      File.exist?(base_path).should == true
      File.exist?(tables_path).should == true
      File.exist?(cubes_path).should == true
    end
  end
  
  it "should drop a database" do
    base_path = File.expand_path('data') + '/socialytical'
    tables_path = File.join(base_path, 'tables')
    cubes_path = File.join(base_path, 'cubes')
    
    FakeFS do
      database = Qubedb::Database.create('socialytical')
      database.path.to_s.should == base_path
    
      File.exist?(base_path).should == true
      File.exist?(tables_path).should == true
      File.exist?(cubes_path).should == true
      
      Qubedb::Database.drop('socialytical')
      
      File.exist?(base_path).should == false
      File.exist?(tables_path).should == false
      File.exist?(cubes_path).should == false
    end
  end
end