import pegs, options, ants/language_v1
export pegs, options

type
  GithubAction* = object
    name*: string
    on*: Dispatch
  
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
    # `type`: string
    options*: seq[string]

  Crons* = object
    cron*: string
  
  Push* = object
    paths*: seq[string]

antDeclareStart(GithubAction)