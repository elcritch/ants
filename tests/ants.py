import yaml

ys = """\
!antExport ImporterConfig:
  cimports: !list: 
    - !ImportConfig:
      name: "rcutils"
      sources: "deps/rcutils/include"
      globs: ["**/*.h"]
"""

yaml.emitter.Emitter.process_tag = lambda self, *args, **kw: None
yaml.add_multi_constructor('!', lambda loader, suffix, node: node)

res = yaml.load(ys, Loader=yaml.Loader)

print(res)