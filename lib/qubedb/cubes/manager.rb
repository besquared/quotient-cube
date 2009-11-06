module Qubedb
  module Cubes
    class Manager
      include TokyoCabinet
    
      attr_accessor :database
    
      def initialize(database)
        @database = database
      end
    
      def find(name)
        if File.exist?(File.join(database.cubes_path, "#{name}.data")
          return Cube.new(database, name)
        else
          return nil
        end
      end
    
      def create(name)
        if find(name)
          raise "A cube by that name already exists"
        else
          cube = create_cube(name)
          index = create_index(name) if cube
        
          if cube and index
            return cube
          else
            raise "Could not create cube #{name}"
          end
        end
      end
    
      def cube_path(name)
        File.join(database.cubes_path, "#{name}.data")
      end
    
      def index_path(name)
        File.join(database.tables_path, "#{name}.index")
      end
    
    protected
      def create_cube(name)
        cube = BDB.new
        begin
          index.tune(-1, -1, -1, -1, -1, BDB::TLARGE | BDB::TDEFLATE)
          if cube.open(cube_path(name), BDB::OCREAT)
            return Cube.new(database, name)
          else
            raise "Could not create cube #{name}, #{table.errmsg}"
          end
        ensure
          table.close
        end
      end
    
      def create_index(name)
        index = BDB.new
        begin
          index.tune(-1, -1, -1, -1, -1, BDB::TLARGE | BDB::TDEFLATE)
          if index.open(index_path(name), BDB::OCREAT)
            return Index.new(database, name)
          else
            raise "Could not create index for table #{name}, #{index.errmsg}"
          end
        ensure
          index.close
        end
      end
    end
  end
end