import macros
from strutils import dedent
export dedent
import language_common
export json, tables, language_common

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
        let fieldParent = fieldTyp
        let fieldName = fieldParent[0]
        let fieldTyp = fieldParent[1]
        let tagName = ident("n" & repr(fieldTyp))

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
        elif repr(fieldName) in ["Table"]:
          let fkind = ident "openArray"
          echo "TABLE: "
          echo treeRepr fieldParent
          let fieldTypB = fieldParent[2]
          quote do:
            template `name`(`val`: `fkind`[(`fieldTyp`, `fieldTypB`)]) {.used.} =
              ## adds values to the field
              `variable`.`name` = toTable(`val`)
        else:
          raise newException(ValueError, "unhandled type: " & repr(fieldName))
      else:
        let tagName = ident("n" & repr(fieldTyp))
        quote do:
          template `name`(`val`: `fieldTyp`) {.used.} =
            ## set field of given name with value
            `variable`.`name` = `val`
    fields.add fproc
  result = fields

type
  NN* = object
  AntMap*[K,V] = seq[(K, V)]

var n*: NN

proc `!`*[T](nn: NN): NN =
  nn

template `!`*[T](nn: NN, objTyp: typedesc[T], blk: untyped): untyped =
  item(objTyp, blk)

template `-`*(blk: string): auto =
  blk


template `-`*[T](typ: typedesc[T], blk: untyped): auto =
  ## alias for `-` template above.
  ##
  item(typ, blk)

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

# template TAG*(a: untyped): NN = n

macro `q`*(a, b: untyped): untyped =
  echo treeRepr a
  result = quote do:
    discard






    

