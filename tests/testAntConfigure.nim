
import ants/configure
import cimport_options
import os
import unittest


var fl = "cimport_example.ants"

if not fl.fileExists():
  fl = "test" / fl

var cimportsCfg: ImporterConfig

test "test run":
  cimportsCfg = ImporterConfig.antConfiguration(
    "tests/cimport_example.ants",
    antsBin = "./ants"
  )

test "test serde":
  check cimportsCfg.cimports[0].name == "rosidl_typesupport_introspection_c"
  check cimportsCfg.cimports[1].name == "rcutils"