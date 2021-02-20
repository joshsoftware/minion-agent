require "crystalizer/json"
require "crystalizer/yaml"
require "csv"

# ---
# foo:
#  bar:
#    baz:
#      - qux
#      - fox

data = File.read("/tmp/foo.txt")

yaml = Crystalizer::YAML.parse data

puts "parsed yaml: #{yaml}"

json = Crystalizer::JSON.serialize yaml

puts json
puts json.class

csv = CSV.new(File.read("/tmp/foo.csv"), headers: true)

while csv.next
  row = csv.row
  puts row.inspect
  puts row.class
  puts row.to_h.to_pretty_json
end
