import macros
from strutils import dedent
export dedent
import json
export json

func str*(val: static[string]): string =
  ## default block string formatting. Currently uses `strutils.dedent`.
  dedent(val)


macro listImpl*(codeBlock: untyped): untyped =
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

type NList* = object
let list* = NList()

template `!`*(list: NList, blk: untyped): untyped =
  listImpl(blk)

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
        let fieldName = fieldTyp[0]
        let fieldTyp = fieldTyp[1]
        let tagName = ident("n" & repr(fieldTyp))

        if repr(fieldName) == "Option":
          quote do:
            template `tagName`(blk: untyped): `fieldTyp` =
              item `fieldTyp`: blk
            template `name`(`val`: `fieldTyp`) {.used.} =
              ## adds values to the field 
              `variable`.`name` = some(`val`)
        elif repr(fieldName) in ["seq"]:
          let fkind = ident "openArray"
          quote do:
            template `tagName`(blk: untyped): `fieldTyp` =
              item `fieldTyp`: blk
            template `name`(`val`: `fkind`[`fieldTyp`]) {.used.} =
              ## adds values to the field
              `variable`.`name`.add(`val`)
        else:
          raise newException(ValueError, "unhandled type: " & repr(fieldName))
      else:
        let tagName = ident("n" & repr(fieldTyp))
        quote do:
          template `tagName`(blk: untyped): `fieldTyp` =
            item `fieldTyp`:
              blk
          template `name`(`val`: `fieldTyp`) {.used.} =
            ## set field of given name with value
            `variable`.`name` = `val`
    fields.add fproc
  result = fields

type NN* = object

let n* = NN()

proc `!`*(nn: NN): NN =
  nn

template `!`*[T](nn: NN, objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

template `-`*[T](blk: T): T =
  blk

template item*[T](typ: typedesc[T], blk: untyped): auto =
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

# template `-`*[T](typ: typedesc[T], blk: untyped): auto =
#   ## alias for `-` template above.
#   ##
#   item(typ, blk)

template `@`*[T](typ: typedesc[T], blk: untyped): auto =
  ## alias for `-` template above.
  ##
  `-`(typ, blk)

template serializeToJson() =
  var ss = MsgStream.init(encodingMode = MSGPACK_OBJ_TO_MAP)
  ss.pack(antConfigValue)
  ss.setPosition(0)
  let jn = ss.toJsonNode()
  echo jn.pretty()

macro `---`*(a: untyped): untyped =
  echo treeRepr(a)
  if repr(a) == "antStart":
    result = quote do:
      antStart()
  elif repr(a) == "antEnd":
    result = quote do:
      antEnd()

macro TAG*(a: untyped): untyped =
  echo "TAG: ", treeRepr(a)
  quote do:
    discard

macro `q`*(a, b: untyped): untyped =
  echo treeRepr a
  result = quote do:
    discard

template `|`*(a: untyped): string =
  a

template antDeclareStart*[T](typ: typedesc[T]): untyped =
  template antStart*(): untyped =
    var antConfigValue* {.inject.}: T = default(typ)
    var antConfigBuff* {.inject.}: string

    settersImpl(typ, antConfigValue)

  template antEnd*(): untyped =
    when defined(nimscript) or defined(nimscripter):
      import ants/msgpack_lite

      let res = pack(antConfigValue)
      antConfigBuff = res
      when defined(nimscript):
        echo res
    else:
      import json, streams, msgpack4nim
      import msgpack4nim/msgpack2json
      serializeToJson()

template antExport*[T](typ: typedesc[T], blk: untyped): untyped =
  antStart()
  blk
  antEnd()



    

