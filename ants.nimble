# Package

version       = "0.1.6"
author        = "Jaremy Creechley"
description   = "ANT: statically typed configurations for Nim (and others)"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["ants"]


# Dependencies

requires "nim >= 1.6.0"
requires "nimscripter >= 1.0.18"
requires "compiler"
requires "cligen"
requires "msgpack4nim >= 0.4.0"
requires "flatty"

task test, "run tests":
  exec "nim c --verbosity:0 -r tests/testAntConfigure.nim"