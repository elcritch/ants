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

macro settersImpl*[T](typ: typedesc[T], variable: typed) =
  ## makes settors for each field in the given `typ`. 
  # echo "setters::"

  let typImpl = getImpl(typ)
  var fields = newStmtList()
  let val = ident("val")
  for node in typImpl[^1][^1]:
    # echo "setters:field: ", node.repr
    let name = 
      if node[0].kind == nnkPostfix: node[0][1]
      else: node[0]
    let fieldTyp = node[1]
    let fproc =
      if fieldTyp.kind == nnkBracketExpr:
        let fieldName = fieldTyp[0]
        let fieldTyp = fieldTyp[1]

        if repr(fieldName) == "Option":
          quote do:
            template `name`(`val`: `fieldTyp`) {.used.} =
              ## adds values to the field 
              `variable`.`name` = some(`val`)
        elif repr(fieldName) in ["seq"]:
          let fkind = ident "openArray"
          quote do:
            template `name`(`val`: `fkind`[`fieldTyp`]) {.used.} =
              ## adds values to the field
              `variable`.`name`.add(`val`)
        else:
          raise newException(ValueError, "unhandled type: " & repr(fieldName))
      else:
        quote do:
          template `name`(`val`: `fieldTyp`) {.used.} =
            ## set field of given name with value
            `variable`.`name` = `val`
    fields.add fproc
  result = fields
  # echo "settersImpl::"
  # echo result.repr

type
  NN* = object
  NList* = object
  NTag* = object
  NQuote* = object
    name*: string

let
  list* = NList()
  n* = NN()
  tag* = NTag()

macro `%`*(a: NN, b: untyped): untyped =
  let id = b[0]
  result = quote do:
    import `id`

template TAG*(a: untyped): NN = n

macro `!`*(nn: NN, nb: NTag): NTag =
  result = quote do:
    TAG

template `!`*(list: NList, blk: untyped): untyped =
  listImpl(blk)

proc `!`*(nn: NN): NN = nn

template `!`*[T](nn: NN, objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

template `!`*[T](objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

macro `!`*[T](objTyp: typedesc[T]): untyped =
  # echo "repr:!: ", objTyp.treeRepr
  result = objTyp

macro `qq`*(foo: untyped): untyped =
  # echo "repr:q: ", foo.treeRepr
  # let qn = nnkAccQuoted.newTree(foo)
  let qn = newStrLitNode repr(foo)
  # echo "res:foo:"
  # echo treeRepr qn
  result = quote do:
    NQuote(name: `qn`)
  # echo "res:q:"
  # echo treeRepr result

macro `!`*(nq: NQuote,  blk: untyped): untyped =
  # item(objTyp, blk)
  # echo "!:nq: ", nq.treeRepr
  # echo "!:blk: ", blk.treeRepr
  let nm = nq[1][1].strVal
  # echo "!:nm: ", nm.treeRepr
  let qnm = nnkAccQuoted.newTree(ident nm)
  result = quote do:
    `qnm`(`blk`)
  # echo "!:res: ", result.repr


macro `!`*(a: untyped, blk: untyped): untyped =
  echo "!:arg: ", a.treeRepr
  if a.kind == nnkSym and a.strVal in ["type"]:
    let qnm = nnkAccQuoted.newTree(ident repr(a))
    result = quote do:
      `qnm`(`blk`)
  else:
    result = quote do:
      item(`a`, `blk`)
  echo "!:res: ", result.repr

macro `-`*[T](a: typedesc[T], blk: untyped): T =
  result = quote do:
    item(`a`, `blk`)

template `-`*[T](obj: T): T = obj

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

template serializeToJson() =
  var ss = MsgStream.init(encodingMode = MSGPACK_OBJ_TO_MAP)
  ss.pack(antConfigValue)
  ss.setPosition(0)
  let jn = ss.toJsonNode()
  echo jn.pretty()

macro `---`*(a: untyped): untyped =
  # echo "---:::", treeRepr(a)
  if repr(a) == "!antStart":
    result = quote do:
      antStart()
  elif repr(a) == "!antEnd":
    result = quote do:
      antEnd()

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



    

