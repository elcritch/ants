import pegs, options, ants/language_common
export pegs, options

type
  ImporterConfig* = object
    cimports*: seq[ImportConfig]

  ImportConfig* = object
    name*: string
    count*: int
    sources*: string
    globs*: seq[string]
    defines*: seq[string]
    includes*: seq[string]
    skipFiles*: seq[string]
    renameFiles*: seq[Replace]
    outdir*: string
    skipProjMangle*: bool
    removeModulePrefixes*: string
    sourceMods*: seq[CSrcMods]
    c2nimCfgs*: seq[C2NimCfg]
  
  CSrcMods* = object
    fileMatch*: Peg
    substitutes*: seq[Replace]
    deletes*: seq[LineDelete]

  C2NimCfg* = object
    fileMatch*: Peg
    extraArgs*: seq[string]
    fileContents*: string
    rawNims*: string

  Replace* = object
    pattern*: Peg
    repl*: string
    comment*: bool
  
  LineDelete* = object
    match*: Peg
    until*: Option[Peg]
    inclusive*: bool


template cimportss*(blk: untyped): untyped =
  antExport ImporterConfig:
    blk

antDeclareStart(ImporterConfig)