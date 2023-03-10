import pegs, tables, ants/language_common
from options import Option
export pegs, Option

type
  GithubAction* = object
    name*: string
    on*: Dispatch
    env*: Table[string, string]
  
  Dispatch* = object
    workflow_dispatch*: WorkFlow
    schedule*: seq[Crons]
    push*: Push

  WorkFlow* = object
    inputs*: Inputs
    test*: string
  
  Inputs* = object
    logLevel*: LogLevel

  LogLevel* = object
    description*: string
    required*: bool
    default*: string
    `type`*: string
    options*: seq[string]

  Crons* = object
    cron*: string
  
  Push* = object
    paths*: seq[string]

# template nDispatch*(blk: untyped): Dispatch = item Dispatch: blk
# template nWorkFlow*(blk: untyped): WorkFlow = item WorkFlow: blk
# template nInputs*(blk: untyped): Inputs = item Inputs: blk
# template nLogLevel*(blk: untyped): LogLevel = item LogLevel: blk
# template nPush*(blk: untyped): Push = item Push: blk

antDeclareStart(GithubAction)