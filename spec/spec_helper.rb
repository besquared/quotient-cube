require 'rubygems'
require 'benchmark'
require 'tempfile'
require 'spec/autorun'

require File.join(File.dirname(__FILE__), '..', 'init')

include TokyoCabinet

def load_fixture(name)
  YAML.load_file(fixture_path("#{name}.yml"))
end

def fixture_path(name)
  File.join(File.dirname(__FILE__), 'fixtures', name)
end