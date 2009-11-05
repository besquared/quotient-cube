require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

describe QuotientCube::Tree::Query::Base do
  describe "With store, product and season dataset" do
    before(:each) do
      @table = Table.new(
        :column_names => [
          'store', 'product', 'season', 'sales'
        ], :data => [
          ['S1', 'P1', 's', 6],
          ['S1', 'P2', 's', 12],
          ['S2', 'P1', 'f', 9]
        ]
      )
  
      @dimensions, @measures = ['store', 'product', 'season'], ['sales']
  
      @cube = QuotientCube::Base.build(
        @table, @dimensions, @measures
      ) do |table, pointers|
        sum = 0
        pointers.each do |pointer|
          sum += table[pointer]['sales']
        end
        sum / pointers.length.to_f
      end
    
      @tempfile = Tempfile.new('database')
      @database = TokyoCabinet::BDB.new
      @database.open(@tempfile.path, BDB::OWRITER | BDB::OCREAT)

      @tree = QuotientCube::Tree::Builder.new(
                  @database, @cube, :prefix => 'prefix').build
      @query = QuotientCube::Tree::Query::Base.new(@tree, 
                  {'store' => 'S1', 'product' => 'P1', 'season' => 's'}, ['sales'])
    end
    
    after(:each) do
      @database.close
    end
  
    it "should get the last specified position" do
      @query.last_specified_position.should == 2
    end
  
    it "should get the last dimension for a node" do
      @query.last_node_dimension(@tree.nodes.root).should == 'season'
    end
  
    it "should return nil if a value doesn't exist for a dimension" do
      node = @query.search(@tree.nodes.root, 'store', 'S3', 0)
      node.should == nil
    end
  
    it "should search a shallow route" do
      node = @query.search(@tree.nodes.root, 'product', 'P1', 0)
      node.should == '2'
    end
  
    it "should search a deep route" do
      root = @tree.nodes.root
      node = @tree.nodes.child(root, 'store', 'S2')
      # acts like a recursion so start from depth 1
      node = @query.search(node, 'season', 'f', 2, 1)
      node.should == '11'
    end
  
    it "should return shallow measures" do
      root = @tree.nodes.root
      measures = @query.search_measures(root, ['sales'])
      measures.should == {'sales' => 9.0}
    end
  
    it "should return measures for root" do
      measures = @query.search_measures(@tree.nodes.root, ['sales'])
      measures.should == {'sales' => 9.0}
    end
  
    it "should return more shallow measures" do
      root = @tree.nodes.root
      node = @tree.nodes.child(root, 'season', 's')
      measures = @query.search_measures(node, ['sales'])
      measures.should == {'sales' => 9.0}
    end
  
    it "should return deep measures" do
      root = @tree.nodes.root
      node = @tree.nodes.child(root, 'store', 'S2')
      measures = @query.search_measures(node, ['sales'])
      measures.should == {'sales' => 9.0}
    end
  end
end