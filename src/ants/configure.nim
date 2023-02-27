import osproc, strformat, msgpack4nim
export msgpack4nim
import flatty/hexprint

proc antConfiguration*[T](
    typ: typedesc[T],
    path: string,
    debug = false,
    systems: seq[string] = @[]
): T =
  ## read value from ant configuration
  let path = quoteShell(path)
  let cmd = fmt"ants --bin -f {path}"
  let outp = execCmdEx(cmd, options={poUsePath})
  
  if outp.exitCode != 0:
    echo "cmd: ", cmd
    raise newException(ValueError, "error runnings config process: " & repr(outp))
  
  if debug:
    echo outp.output.hexPrint()
  
  # read and serde the config
  let ss = MsgStream.init(outp.output, encodingMode = MSGPACK_OBJ_TO_MAP)
  result = default(T)
  ss.unpack(result)

