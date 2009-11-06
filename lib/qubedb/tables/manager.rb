module Qubedb
  module Tables
    class Manager
      include TokyoCabinet
    
      attr_accessor :database
    
      def initialize(database)
        @database = database
      end
    
      def find(name)
        if File.exist?(File.join(database.tables_path, "#{name}.data"))
          return Table.new(database, name)
        else
          return nil
        end
      end
    
      def create(name)
        if find(name)
          raise "A table by that name already exists"
        else
          table = create_table(name)
          index = create_index(name) if table
        
          if table and index
            return table
          else
            raise "Could not create table #{name}"
          end
        end
      end
              
    protected
      def create_table(name)
      end
    
      def create_index(name)
      end
    end
  end
end