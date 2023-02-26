import sequtils, macros, options
import pegs
import nimscripter, nimscripter/variables

import compiler/[ast]

proc fromVm*(t: typedesc[Peg], node: PNode): Peg =
  if node.kind == nkStrLit:
    peg(node.strVal)
  else:
    raise newException(VMParseError, "Cannot convert to: " & $t)

proc runConfigScript*[T](path: string): T =
  let
    intr = loadScript(
      NimScriptPath(path),
      # stdPath = "stdlib/",
      searchPaths = @["src"],
      defines = @{"nimscript": "true",
                  "nimconfig": "true",
                  "nimscripter": "true"})
  
  getGlobalNimsVars intr:
    config = default(T)
  result = config
