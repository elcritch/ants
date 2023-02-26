import pegs

type
  ImporterConfig* = object
    imports*: seq[ImportConfig]

  ImportConfig* = object
    name*: string
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
    until*: Peg
    inclusive*: bool

var cImportConfigs* = ImporterConfig()

proc addConfig*(cfg: ImportConfig) =
  cImportConfigs.imports.add cfg
