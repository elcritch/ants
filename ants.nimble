# Package

version       = "0.3.15"
author        = "Jaremy Creechley"
description   = "ANT: statically typed configurations for Nim (and others)"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["ants"]


# Dependencies

# requires "nim <= 1.6.10"
# requires "nimscripter >= 1.0.18"
requires "https://github.com/elcritch/nimscripter.git#add-compiler-deps >= 1.0.20"
requires "compiler"
requires "cligen"
requires "msgpack4nim >= 0.4.0"
requires "flatty"
requires "yaml"

task test, "run tests":
  exec "nim c --verbosity:0 -r tests/testAntConfigure.nim"