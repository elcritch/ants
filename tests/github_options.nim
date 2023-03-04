import pegs, options, ants/language_v1
export pegs, options

type
  GithubAction* = object
    name*: string
    on*: Dispatch
  
  Dispatch* = object
    workflow_dispatch*: WorkFlow
    schedule*: seq[Crons]
    push*: seq[Push]

  WorkFlow* = object
    inputs*: Inputs
  
  Inputs* = object
    logLevel*: LogLevel

  LogLevel* = object
    description*: string
    required*: bool
    default*: string
    # `type`: string
    options*: seq[string]

  Crons* = object
  Push* = object

antDeclareStart(GithubAction)