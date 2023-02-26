import ants, tables
import cimport_options

type
  AntsOptions* = object
    file*: string
    json*: bool

const dflOpts = AntsOptions(
  json: false
)

import cligen

const
  Short = { "file": 'f',
            "json": 'j',
            }.toTable()

var app = initFromCL(dflOpts, short = Short)
echo "app: ", $(app)
if app.json:
  let res = runConfigScriptJson(app.file)
  echo res.pretty()
else:
  let res = runConfigScript(ImporterConfig, app.file)
  echo "result: ", repr(res)

