import sequtils, macros, options
import pegs, tables
import nimscripter, nimscripter/variables
import json

import compiler/[ast]

type
  AntsOptions* = object
    file*: string
    json*: bool

const dflOpts = AntsOptions(
  json: false
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
  
proc runConfigScriptJson*(path: string): JsonNode =
  let
    intr = loadScript(
      NimScriptPath(path),
      searchPaths = @["src"] & systems,
      defines = @{"nimscript": "true",
                  "nimconfig": "true",
                  "nimscripter": "true"})
  
  getGlobalNimsVars intr:
    antConfigJson: JsonNode
  result = antConfigJson

when isMainModule: # Preserve ability to `import api`/call from Nim
  const
    Short = { "file": 'f',
              "json": 'j',
              }.toTable()
  import cligen

  var app = initFromCL(dflOpts, short = Short)
  # echo "app: ", $(app)
  if app.json:
    let res = runConfigScriptJson(app.file)
    # echo res.pretty()
