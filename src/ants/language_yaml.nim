import macros, json, tables
from strutils import dedent
from language_v1 import settersImpl, item, pack_type

export json, dedent, tables, pack_type

func str*(val: static[string]): string =
  ## default block string formatting. Currently uses `strutils.dedent`.
  dedent(val)

macro listImpl*(codeBlock: untyped): untyped =
  ## turns each line in the passed in code-block into an array:
  ## 
  result = newNimNode(nnkBracket)
  for ch in codeBlock.children:
    result.add(ch)

macro mapImpl*(codeBlock: untyped): untyped =
  ## turns each line in the passed in code-block into an array:
  ## 
  echo "mapImpl::"
  echo treeRepr codeBlock
  result = newNimNode(nnkTableConstr)
  for ch in codeBlock.children:
    let nm = newStrLitNode repr(ch[0])
    let val = ch[1]
    let r = quote do:
      {"a": 1, "b": 2}
    echo "r:"
    echo treeRepr(r)
    result.add nnkExprColonExpr.newTree(nm, val)
    # result.add(ch)
  echo "res:"
  echo repr(result)

type
  NN* = object
  NList* = object
  NTag* = object
  NQuote* = object
    name*: string
  NMap* = object

let
  list* = NList()
  map* = NMap()
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

template `!`*(list: NMap, blk: untyped): untyped =
  mapImpl(blk)

proc `!`*(nn: NN): NN = nn

template `!`*[T](nn: NN, objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

template `!`*[T](objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

macro `!`*[T](objTyp: typedesc[T]): untyped =
  result = objTyp

macro `qq`*(foo: untyped): untyped =
  let qn = newStrLitNode repr(foo)
  result = quote do:
    NQuote(name: `qn`)

macro `!`*(nq: NQuote,  blk: untyped): untyped =
  let nm = nq[1][1].strVal
  let qnm = nnkAccQuoted.newTree(ident nm)
  result = quote do:
    `qnm`(`blk`)

macro `-`*[T](a: typedesc[T], blk: untyped): T =
  result = quote do:
    item(`a`, `blk`)

template `-`*[T](obj: T): T = obj

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



    

