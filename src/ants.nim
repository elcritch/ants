import sequtils, macros, options
import pegs, tables
import nimscripter, nimscripter/variables
import json, osproc

import msgpack4nim
import msgpack4nim/msgpack2json
import flatty/hexprint


import compiler/[ast]

type
  AntsOptions* = object
    file*: string
    bin*: bool
    hex*: bool
    paths*: seq[string]

const dflOpts = AntsOptions(
  bin: false
)

proc fromVm*(t: typedesc[Peg], node: PNode): Peg =
  if node.kind == nkStrLit:
    peg(node.strVal)
  else:
    raise newException(VMParseError, "Cannot convert to: " & $t)

proc runConfigScript*[T](typ: typedesc[T], path: string, systems: seq[string]): T =
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
  
proc runConfigScript*(path: string, systems: seq[string]): string =
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

  let nimDump = execProcess("nim dump --verbosity:0 --dump.format:json json").
                    parseJson()["lib_paths"]
  var systems: seq[string]
  for pthjn in nimDump:
    systems.add(pthjn.getStr())
  for pth in app.paths:
    systems.add(pth)

  let res = runConfigScript(app.file, systems)
  if app.bin:
    echo res
  elif app.hex:
    echo res.hexPrint()
  else:
    echo res.toJsonNode().pretty()
