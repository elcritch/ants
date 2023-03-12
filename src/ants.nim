import sequtils, macros, options
import pegs, tables, sets
import nimscripter, nimscripter/variables
import json, osproc, os

import msgpack4nim
import msgpack4nim/msgpack2json
import flatty/hexprint
import yaml


import compiler/[ast]

type
  AntsOptions* = object
    file*: string
    bin*: bool
    hex*: bool
    stringify*: bool
    yaml*: bool
    json*: bool
    debug*: bool
    paths*: seq[string]

const dflOpts = AntsOptions(
  bin: false,
  json: true
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
                    parseJson()
                    # ["lib_paths"]
  var systems: HashSet[string]
  systems.incl(nimDump["libpath"].getStr)
  for pthjn in nimDump["lazyPaths"]:
    systems.incl(pthjn.getStr())
  for pth in app.paths:
    systems.incl(pth)

  if app.debug:
    echo "system paths: ", systems.toSeq

  if not app.file.fileExists():
    raise newException(ValueError, "script doesn't exist: " & app.file)
  let res = runConfigScript(app.file, systems.toSeq)
  if app.bin:
    echo res
  elif app.stringify:
    echo res.stringify()
  elif app.hex:
    echo res.hexPrint()
  elif app.yaml:
    let js = res.toJsonNode().pretty()
    let ym = loadAs[YamlNode](js)
    echo ym.dump()
  elif app.json:
    echo res.toJsonNode().pretty()
  else:
    echo res.toJsonNode().pretty()
