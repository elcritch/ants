import osproc, strformat, msgpack4nim
export msgpack4nim
import flatty/hexprint

proc antConfiguration*[T](
    typ: typedesc[T],
    path: string,
    debug = false,
    antsBin = "ants",
    systems: seq[string] = @[]
): T =
  ## read value from ant configuration
  let qpath = quoteShell(path)
  let cmd = fmt"{antsBin} --bin -f:{qpath}"
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

