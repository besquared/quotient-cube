require File.join(File.dirname(__FILE__), '..', 'init')

require 'rubygems'
require 'benchmark'
require 'tempfile'

include KyotoCabinet

def load_fixture(name)
  YAML.load_file(fixture_path("#{name}.yml"))
end

def fixture_path(name)
  File.join(File.dirname(__FILE__), 'fixtures', name)
end

RSpec.configure do |c|
  # declare an exclusion filter
  # c.filter_run_excluding :example => :products
  # c.filter_run :only => true
end