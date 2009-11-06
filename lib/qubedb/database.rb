#
# Represents a qube database
#
module Qubedb
  class Database
    attr_accessor :path
    attr_accessor :name
    attr_accessor :tables
    attr_accessor :cubes
    
    def initialize(path, name)
      @path = path
      @name = name
      @table = Tables::Manager.new(self)
      @cubes = Cubes::Manager.new(self)
    end
    
    def select(name, fields = :all, conditions = {})
      if table = tables.find(name)
        return table.select(fields, conditions)
      elsif cube = cubes.find(name)
        return cube.select(fields, conditions)
      else
        raise "No tables or cubes found with name #{name}"
      end
    end
    
    def path
      self.class.path(path, name)
    end
    
    def tables_path
      self.class.tables_path(path, name)
    end
    
    def cubes_path
      self.class.cubes_path(path, name)
    end
    
    class << self
      def create(path, name)
        write_path(path, name)
        write_tables_path(path, name)
        write_cubes_path(path, name)
        new(path, name)
      end
      
      def open(opath, name)
        if path(opath, name)
          new(opath, name)
        else
          raise "Database not found"
        end
      end
      
      #
      # Path management
      #
      
      def path(path, name)
        File.join(path, name)
      end

      def write_path(wpath, name)
        FileUtils.mkpath(path(wpath, name))
      end
      
      def tables_path(tpath, name)
        File.join(path(tpath, name), 'tables')
      end
      
      def write_tables_path(path, name)
        FileUtils.mkpath(tables_path(path, name))
      end
      
      def cubes_path(cpath, name)
        File.join(path(cpath, name), 'cubes')
      end
      
      def write_cubes_path(path, name)
        FileUtils.mkpath(cubes_path(path, name))
      end
    end
  end
end