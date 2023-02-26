import sequtils, macros, options
import pegs, tables
import nimscripter, nimscripter/variables
import json

import msgpack4nim
import msgpack4nim/msgpack2json
import flatty/hexprint


import compiler/[ast]

type
  AntsOptions* = object
    file*: string
    bin*: bool
    hex*: bool

const dflOpts = AntsOptions(
  bin: false
)

var systems = @[
  "/Users/jaremycreechley/.asdf/installs/nim/1.6.10/nimble/pkgs/flatty-0.3.4",
  "/Users/jaremycreechley/.asdf/installs/nim/1.6.10/nimble/pkgs/msgpack4nim-0.3.1",
]

proc fromVm*(t: typedesc[Peg], node: PNode): Peg =
  if node.kind == nkStrLit:
    peg(node.strVal)
  else:
    raise newException(VMParseError, "Cannot convert to: " & $t)

proc runConfigScript*[T](typ: typedesc[T], path: string): T =
  let
    intr = loadScript(
      NimScriptPath(path),
      searchPaths = @["src"] & systems,
      defines = @{"nimscript": "true",
                  "nimconfig": "true",
                  "antsDirect": "true",
                  "nimscripter": "true"})
  
  # getGlobalNimsVars intr:
  #   antConfigValue: T
  # result = antConfigValue
  
proc runConfigScript*(path: string): string =
  let
    intr = loadScript(
      NimScriptPath(path),
      searchPaths = @["src"] & systems,
      defines = @{"nimscript": "true",
                  "nimconfig": "true",
                  "nimscripter": "true"})
  
  getGlobalNimsVars intr:
    antConfigBuff: string
  result = antConfigBuff

when isMainModule: # Preserve ability to `import api`/call from Nim
  const
    Short = { "file": 'f',
              "bin": 'b',
              }.toTable()
  import cligen

  var app = initFromCL(dflOpts, short = Short)
  let res = runConfigScript(app.file)
  if app.bin:
    echo res
  elif app.hex:
    echo res.hexPrint()
  else:
    echo res.toJsonNode().pretty()
