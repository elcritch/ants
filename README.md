# Ant

Ant provides a statically checked configuration syntax similar to YAML. However, all types are Nim objects and constructs. 

Here's a short example:

```nim
import ants/configure, cimport_options

antExport ImporterConfig:
  cimports:list: item ImportConfig:
    name: "rcutils"
    sources: "deps/rcutils/include"
    globs: ["**/*.h"]
    skipFiles:list:
      "rcutils/stdatomic_helper/win32/stdatomic.h"
      "rcutils/stdatomic_helper/gcc/stdatomic.h"
      "rcutils/stdatomic_helper.h"
    includes:list:
      "deps/rcutils/include"

    renameFiles:list:
      Replace(pattern: peg"^'string.' .+", repl: "rstring$1")
    sourceMods:list:
      - CSrcMods:
        fileMatch: peg"'rcutils/visibility_control.h'"
        deletes:list:
          LineDelete(match: peg"'RCUTILS_PUBLIC'")
```

This can be run by the `ants` cli tool to print out a JSON or MsgPack form of the config. There's an option to use `ants` as a library form that will recreate the Nim object's diretly. You can also embed the Nim interpreter directly into you app.  

```sh
ants -f tests/cimport_example.ants > output.json
ants -b -f tests/cimport_example.ants > output.mpack
```

## How does this work? 

This is nice and all, but doesn't it require a complicated macro with complicated rules and broken auto-complete?

Nope!  There are only a few basic constructs which are used to provide a nice syntax: 

The `list` macro that turns any lines passed to it into an array. This can be used with openArray's to add to sequences.  

```nim
var x: array[2, int]
x = list:
  1
  2

assert x == [1,2]
```

The `-` or `item` templates takes an object type and makes setters for each field. The setters can be used in a do block passed after the type. The setters are normal Nim proc's and can be called in any way Nim supports, including using `:` block calls. Note that by defining setter functions autocomplete can help find options.

Here's an example: 

```nim
type Foo = object
  field1: int
  field2: string
  field3: seq[string]

var foo: Foo
foo = - Foo:
  field1(1)
  field2: "test"
  field3 ["hello", "world"]

assert foo == Foo(field1: 1, field2: @["hello", "world"])
```

Combining these you get a YAML! See:

```nim
var fooBars: array[2, Foo]
fooBars = list:
  - Foo:
    field1: 23
  - Foo:
    field1: 34
    field2: "test"
    field3:list:
      "hello"
      "world"
```
