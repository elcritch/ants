
import ants/configure
import cimport_options
import print, os

var fl = "cimport_example.ants"

if not fl.fileExists():
  fl = "test" / fl

let cimportsCfg = ImporterConfig.antConfiguration(
  "tests/cimport_example.ants"
)

echo "cimportsCfg: "
print cimportsCfg