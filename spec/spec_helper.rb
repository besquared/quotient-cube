require 'rubygems'
require 'benchmark'
require 'tempfile'
require 'spec/autorun'

require File.join(File.dirname(__FILE__), '..', 'init')

include TokyoCabinet

def load_fixture(name)
  YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures', "#{name}.yml"))
end