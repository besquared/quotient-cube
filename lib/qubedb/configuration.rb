module Qubedb
  class Configuration
    class << self
      attr_accessor :configuration
      
      def configure(configuration = {})
        configuration.symbolize_keys!
        @configuration = configuration
      end
      
      def configuration
        @configuration || {}
      end
      
      def data_path
        File.expand_path(configuration[:data_path] || "data")
      end
      
      def temp_path
        File.expand_path(configuration[:temp_path] || "/tmp")
      end
    end
  end
end