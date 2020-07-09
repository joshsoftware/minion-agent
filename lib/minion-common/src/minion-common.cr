# This is the set of little libraries, structures, and utilities that are shared
# between other parts of the Minion codebase.

require "./minion/*"

#  frame.cr
# Encapsulated the data payload that Minion passes around.

#  io_details.cr
# A set of parameters used when reading data off of an IO that contains length
# msgpack'd Frame classes with length encoding.

#   monkeys/
# All of the monkey patches to the standard lib go here.

#  timer.cr
# This is a simple implementation of a timer class for creating periodic events.

#  types.cr
# Some of the type union are repeated many times in the code. It is a lot more
# readable to just define them a single time here.

#  uuid.cr
# The code uses a nonstandard UUID that encodes the nano-second precision time stamp
# along with a six byte uniqifier.

#  util.cr
# These are collected utility methods.

module Minion::Common
  VERSION = "0.1.2"
end
