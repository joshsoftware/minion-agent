require "option_parser"
require "minion-common"
require "./client"
require "./agent/*"

Minion::Agent.exec
