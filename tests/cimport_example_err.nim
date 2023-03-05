import ants/language_v1
import cimporter/configs

antExport ImporterConfig:
  cimports:list:
    - ImportConfig:
      name: "rosidl_typesupport_introspection_c"
      sources: "deps/rosidl/rosidl_typesupport_introspection_c/include"
      globs: ["**/*.h"]
      includes: [
        "deps/rcutils/include",
        "deps/rosidl/rosidl_typesupport_introspection_c/include",
        ]
      defines: []
      skipFiles: []
    - ImportConfig:
      name: "rosidl_runtime_c"
      sources: "deps/rosidl/rosidl_runtime_c/include"
      globs: ["**/*.h"]
      includes: [
        "deps/rcutils/include",
        "deps/rosidl/rosidl_runtime_c/include",
        "deps/rosidl/rosidl_typesupport_interface/include",
        "deps/rosidl/rosidl_typesupport_introspection_c/include",
        ]
      defines: []
      skipFiles: []
      renameFiles:list:
        - Replace:
          pattern: peg"^'string.' .+"
          repl: "rstring$1"

      c2NimCfgs:list:
        - C2NimCfg:
          fileMatch: peg"'u16string.h'"
          rawNims: str"""
              type
                uintLeast16T * {.importc: "uint_least16_t", header: "stddef.h", bycopy.} = object
              """
        - C2NimCfg:
          fileMatch: peg"'service_type_support_struct.h'"
          rawNims: str"""
              import rcutils/allocator
              """
        - C2NimCfg:
          fileMatch: peg"'message_initialization.h'"
          rawNims: str"""
              import ../rosidl_typesupport_introspection_c/message_introspection

              export message_introspection
              """
      sourceMods:list:
        - CSrcMods:
          name: "rosidl_adapter"
          sources: "deps/rosidl/rosidl_adapter/include"
          globs: ["**/*.h"]
          includes: [
            "deps/rcutils/include",
            "deps/rosidl/rosidl_runtime_c/include",
            "deps/rosidl/rosidl_typesupport_interface/include",
            "deps/rosidl/rosidl_typesupport_introspection_c/include",
            ]

        - CSrcMods:
          name: "rosidl_parser"
          sources: "deps/rosidl/rosidl_parser/include"
          globs: ["**/*.h"]
          includes: [
            "deps/rcutils/include",
            "deps/rosidl/rosidl_runtime_c/include",
            "deps/rosidl/rosidl_typesupport_interface/include",
            "deps/rosidl/rosidl_typesupport_introspection_c/include",
            ]

        - CSrcMods:
          name: "rosidl_typesupport_introspection_c"
          sources: "deps/rosidl/rosidl_typesupport_introspection_c/include"
          globs: ["**/*.h"]
          includes: [
            "deps/rcutils/include",
            "deps/rosidl/rosidl_runtime_c/include",
            "deps/rosidl/rosidl_typesupport_interface/include",
            "deps/rosidl/rosidl_typesupport_introspection_c/include",
            ]
          
        