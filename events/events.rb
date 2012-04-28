require File.join(File.dirname(__FILE__), '..', 'init')

require 'fastercsv'

include TokyoCabinet

columns = [
  'network_id','user_id','meta_user_id',
  'event_name','controller','action',
  'client_name','user_agent_name','user_agent_version',
  'continent','country',
  'd28_events','d14_events','d7_events','d1_events'
]

data = []
FasterCSV.new(File.open("data/events.csv"), :headers => true).each do |row|
  data_row = []
  columns.each do |column|
    data_row << row[column] || 'Unknown'
  end
  data << data_row
end

@table = Table.new(
  :column_names => columns,
  :data => data
)

@dimensions = ['network_id','user_id','meta_user_id',
'event_name','controller','action',
'client_name','user_agent_name','user_agent_version',
'continent','country']

@measures = ['d28_events','d14_events','d7_events','d1_events']

@cube = QuotientCube::Base.build(
  @table, @dimensions, @measures
) do |table, pointers|
  sums = {}
  pointers.each do |pointer|
    @measures.each do |measure|
      sums[measure] ||= 0
      sums[measure] += table[pointer][measure].to_i
    end
  end
  
  @measures.map{|m| sums[m]}
end

@database = TokyoCabinet::BDB.new
@database.open('events.tcb', BDB::OTRUNC | BDB::OCREAT)

@tree = QuotientCube::Tree::Builder.build(@database, @cube, :prefix => 'prefix')

puts QuotientCube::Tree::Query::Point.new(
  @tree, {'network_id' => '1'}, ['d28_events']
).process.inspect

@database.close