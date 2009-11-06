module Qubedb
  class Database
    attr_accessor :path
    attr_accessor :name
    attr_accessor :tables
    attr_accessor :cubes
    
    def initialize(name)
      @name = name
      @tables = Tables::Manager.new(self)
      @cubes = Cubes::Manager.new(self)
    end
    
    def query_table(name, fields = :all, conditions = {})
      if table = tables.find(name)
        return table.select(fields, conditions)
      else
        raise "No tables found with name #{name}"
      end
    end
    
    def query_cube(name, measures = :all, conditions = {})
      if cube = cubes.find(name)
        return cube.select(fields, conditions)
      else
        raise "No cubes found with name #{name}"
      end
    end
    
    def path
      self.class.path(name)
    end
    
    def tables_path
      self.class.tables_path(name)
    end
    
    def cubes_path
      self.class.cubes_path(name)
    end
    
    class << self
      def create(name)
        write_path(name)
        write_tables_path(name)
        write_cubes_path(name)
        new(name)
      end
      
      def open(name)
        if File.exist?(path(name))
          new(name)
        else
          raise "Database not found"
        end
      end
      
      def drop(name)
        FileUtils.rm_rf(path(name))
        FileUtils.rm_rf(tables_path(name))
        FileUtils.rm_rf(cubes_path(name))
      end
      
      #
      # Path management
      #
      
      def path(name)
        File.join(File.expand_path(Configuration.data_path), name)
      end

      def write_path(name)
        FileUtils.mkpath(path(name))
      end
      
      def tables_path(name)
        File.join(path(name), 'tables')
      end
      
      def write_tables_path(name)
        FileUtils.mkpath(tables_path(name))
      end
      
      def cubes_path(name)
        File.join(path(name), 'cubes')
      end
      
      def write_cubes_path(name)
        FileUtils.mkpath(cubes_path(name))
      end
    end
  end
end