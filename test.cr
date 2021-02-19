require "crystalizer/json"
require "crystalizer/yaml"

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
