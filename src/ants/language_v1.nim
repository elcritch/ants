import macros
from strutils import dedent
export dedent


func str*(val: static[string]): string =
  ## default block string formatting. Currently uses `strutils.dedent`.
  dedent(val)

macro list*(codeBlock: untyped): untyped =
  ## turns each line in the passed in code-block into an array:
  ## 
  ##     list: 
  ##       1
  ##       2
  ## 
  ## becomes:
  ## 
  ##     [ 1, 2, ]
  ## 
  result = newNimNode(nnkBracket)
  for ch in codeBlock.children:
    result.add(ch)

macro settersImpl*[T](typ: typedesc[T], variable: typed) =
  ## makes settors for each field in the given `typ`. 
  let typImpl = getImpl(typ)
  var fields = newStmtList()
  let val = ident("val")
  for node in typImpl[^1][^1]:
    let name = 
      if node[0].kind == nnkPostfix: node[0][1]
      else: node[0]
    let fieldTyp = node[1]
    let fproc =
      if fieldTyp.kind == nnkBracketExpr:
        let fieldTyp = fieldTyp[1]
        quote do:
          template `name`(`val`: openArray[`fieldTyp`]) {.used.} =
            ## adds values to the field 
            `variable`.`name`.add(`val`)
      else:
        quote do:
          template `name`(`val`: `fieldTyp`) {.used.} =
            ## set field of given name with value
            `variable`.`name` = `val`
    fields.add fproc
  result = fields

template `-`*[T](typ: typedesc[T], blk: untyped): auto =
  ## helps construct an object using "block call" syntax like:
  ##    
  ##     item MyObject:
  ##        field1: "value"
  ##        field2: 33 
  ## 
  ## This template provides 'setters' for each field in the object. 
  ## These can be found via auto-complete. 
  ## 
  ## Because they're functions, you can also call them however normal
  ## functions can be called:
  ## 
  ##     item MyObject:
  ##        field2 33
  ##        field1("value")
  ##        myValue.field3()
  ## 
  block:
    var val: T
    settersImpl(typ, val)
    blk
    val

template item*[T](typ: typedesc[T], blk: untyped): auto =
  ## alias for `-` template above.
  ##
  `-`(typ, blk)

import json
export json

proc `%`*(n: char): JsonNode = %(n.int)
proc `%`*[T](n: set[T]): JsonNode =
  result = newJArray()
  for e in items(n): result.add(% e)
proc `%`*[T](o: ref T): JsonNode =
  if o.isNil:
    result = newJNull()
  else:
    result = %(o[])

template antExport*[T](typ: typedesc[T], blk: untyped) =
  var antConfigValue* {.inject.}: T = default(typ)
  var antConfigBuff* {.inject.}: string

  settersImpl(typ, antConfigValue)

  blk

  when defined(nimscripter):
    import ants/msgpack_lite

    let res = pack(antConfigValue)
    antConfigBuff = res
    # echo res
  else:
    import json
    import msgpack4nim
    import msgpack4nim/msgpack2json

    var ss = MsgStream.init(encodingMode = MSGPACK_OBJ_TO_MAP)
    ss.pack(antConfigValue)
    ss.setPosition(0)
    let jn = ss.toJsonNode()
    echo jn.pretty()
    
