import pegs
import msgpack4nim
import json
import tests/cimport_options

let data = readAll(open("out.mpack"))

let ss = MsgStream.init(data, encodingMode = MSGPACK_OBJ_TO_MAP)
var imp: ImporterConfig
ss.unpack(imp)
let jn = % imp

echo "imp: ", jn.pretty()
