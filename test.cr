# ---
#foo:
#  bar:
#    baz:
#      - qux
#      - fox

require "crystalizer/yaml"

alias Inner = Hash(String, Array(String))
alias Outer = Hash(String, Inner)

data = File.read("/tmp/foo.txt")
pd = Crystalizer::YAML.deserialize(data, to: Outer)

puts pd.inspect
