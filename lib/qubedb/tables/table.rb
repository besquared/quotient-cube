module Qubedb
  module Tables
    class Table
      attr_accessor :database
      attr_accessor :name
    
      def initialize(database, name)
        @database = database
        @name = name
      end
      
      class << self
        def create(database, name)
        end
        
        def create_table(database, name)
          table = TDB.new
          begin
            if table.open(data_path(database, name), TDB::OCREAT)
              return new(database, name)
            else
              raise "Could not create table #{name}, #{table.errmsg}"
            end
          ensure
            table.close
          end
        end
        
        def create_index(table, name)
          index = BDB.new
          begin
            index.tune(-1, -1, -1, -1, -1, BDB::TLARGE | BDB::TDEFLATE)
            if index.open(index_path(name), BDB::OCREAT)
              return Index.new(table, name)
            else
              raise "Could not create index for table #{name}, #{index.errmsg}"
            end
          ensure
            index.close
          end
        end
        
        def data_path(database, name)
          File.join(database.tables_path, "#{name}.data")
        end

        def index_path(database, table)
          File.join(database.tables_path, "#{name}.index")
        end
      end
    end
  end
end