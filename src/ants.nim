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

proc fromVm*(t: typedesc[Peg], node: PNode): Peg =
  if node.kind == nkStrLit:
    peg(node.strVal)
  else:
    raise newException(VMParseError, "Cannot convert to: " & $t)

proc runConfigScript*[T](typ: typedesc[T], path: string): T =
  let
    intr = loadScript(
      NimScriptPath(path),
      # stdPath = "stdlib/",
      searchPaths = @["src"],
      defines = @{"nimscript": "true",
                  "nimconfig": "true",
                  "nimscripter": "true"})
  
  getGlobalNimsVars intr:
    configs: T
  result = configs

when isMainModule: # Preserve ability to `import api`/call from Nim
  const
    Short = { "file": 'f',
              "json": 'j',
              }.toTable()
  import cligen

  var app = initFromCL(dflOpts, short = Short)
  echo "app: ", $(app)
  if app.json:
    let res = runConfigScript(JsonNode, app.file)
    echo res.pretty()
