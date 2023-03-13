import macros
from strutils import dedent
export dedent
import json, tables
export json, tables

func str*(val: static[string]): string =
  ## default block string formatting. Currently uses `strutils.dedent`.
  dedent(val)

var setterLevel* {.compileTime.} = "base"
var setterLevelStack* {.compileTime.} = @["base"]

macro settersImpl*[T](typ: typedesc[T], variable: typed) =
  ## makes settors for each field in the given `typ`. 
  let typImpl = getImpl(typ)
  var fields = newStmtList()
  let val = ident("val")
  let variable = ident(repr(variable))
  let setterLevelVar = ident("setterLevel")
  let setterId = newStrLitNode(setterLevel)

  for node in typImpl[^1][^1]:
    let name = 
      if node[0].kind == nnkPostfix: node[0][1]
      else: node[0]
    let nameId = newStrLitNode(repr(name))
    let fieldTyp = node[1]
    let fproc =
      if fieldTyp.kind == nnkBracketExpr:
        let fieldParent = fieldTyp
        let fieldName = fieldParent[0]
        let fieldTyp = fieldParent[1]
        let tagName = ident("n" & repr(fieldTyp))

        if repr(fieldName) == "Option":
          quote do:
            template `name`(`val`: `fieldTyp`) {.used.} =
              ## adds values to the field 
              when `setterId` != `setterLevelVar`:
                {.error: "Cannot use setter outside it's scope: " & $setterLevel & " : " & repr(`nameId`).}
              `variable`.`name` = some(`val`)
        elif repr(fieldName) in ["seq"]:
          let fkind = ident "openArray"
          quote do:
            template `name`(`val`: `fkind`[`fieldTyp`]) {.used.} =
              ## adds values to the field
              when `setterId` != `setterLevelVar`:
                {.error: "Cannot use setter outside it's scope: " & $setterLevel & " : " & repr(`nameId`).}
              `variable`.`name`.add(`val`)
        elif repr(fieldName) in ["Table"]:
          let fkind = ident "openArray"
          # echo "TABLE: "
          # echo treeRepr fieldParent
          let fieldTypB = fieldParent[2]
          quote do:
            template `name`(`val`: `fkind`[(`fieldTyp`, `fieldTypB`)]) {.used.} =
              ## adds values to the field
              when `setterId` != `setterLevelVar`:
                {.error: "Cannot use setter outside it's scope: " & $setterLevel & " : " & repr(`nameId`).}
              `variable`.`name` = toTable(`val`)
        else:
          raise newException(ValueError, "unhandled type: " & repr(fieldName))
      else:
        let tagName = ident("n" & repr(fieldTyp))
        quote do:
          template `name`(`val`: `fieldTyp`) {.used.} =
            ## set field of given name with value
            when `setterId` != `setterLevelVar`:
              {.error: "Cannot use setter outside it's scope: " & $setterLevel & " : " & repr(`nameId`).}
              # raise newException(ValueError, "Cannot use setter outside it's scope: " & $setterLevel & " : " & repr(`nameId`))
            `variable`.`name` = `val`
    fields.add fproc
  result = fields

type
  NN* = object

var n*: NN

proc `!`*[T](nn: NN): NN =
  nn

template `!`*[T](nn: NN, objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

template `-`*(blk: string): auto =
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
    static:
      setterLevel = $typ
      setterLevelStack.add(setterLevel)
    var antConfigValue {.inject.}: T
    settersImpl(typ, antConfigValue)
    blk
    static:
      discard setterLevelStack.pop()
      setterLevel = setterLevelStack[^1]
    antConfigValue

proc pack_type*[StringStream; K, V](s: StringStream, val: Table[K,V]) =
  s.pack_map(val.len)
  for field, value in val:
    s.pack(field)
    s.pack(value)
proc pack_type*[StringStream; K, V](s: StringStream, val: OrderedTable[K,V]) =
  s.pack_map(val.len)
  for field, value in val:
    s.pack(field)
    s.pack(value)

template antStringify*[T](tup: typedesc[T], tostr, fromstr: untyped) =
  proc pack_type*[StringStream](s: StringStream, val: T) =
    s.pack(tostr(val))
  proc unpack_type*[StringStream](s: StringStream, val: var T) =
    var ps: string
    s.unpack(ps)
    val = fromstr(ps)

template serializeToJson() =
  var ss = MsgStream.init(encodingMode = MSGPACK_OBJ_TO_MAP)
  ss.pack(antConfigValue)
  ss.setPosition(0)
  let jn = ss.toJsonNode()
  echo jn.pretty()


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
      # when defined(nimscript):
      #   echo res
    else:
      import json, streams, msgpack4nim
      import msgpack4nim/msgpack2json
      serializeToJson()

template antExport*[T](typ: typedesc[T], blk: untyped): untyped =
  antDeclareStart(typ)
  antStart()
  blk
  antEnd()



    

