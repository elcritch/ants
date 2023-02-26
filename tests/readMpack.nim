import pegs, msgpack4nim, json
import cimport_options

let data = readAll(open("out.mpack"))

let ss = MsgStream.init(data, encodingMode = MSGPACK_OBJ_TO_MAP)
var imp: ImporterConfig
ss.unpack(imp)
let jn = % imp

echo "imp: ", jn.pretty()
