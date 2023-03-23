directory2019 =
  __DIR__
  |> Path.join("_draft2019-09")
  |> Path.expand()

omit_modules = ~w(refRemote.json anchor.json dynamicRef.json defs.json id.json
  format.json)

omit_describes = [
  # no external URIs.
  {"ref.json", 6},
  # no support for relative uri (for now)
  {"ref.json", 11},
  # currently no support for unevaluated
  {"ref.json", 13},
  # no floating point multiples
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  # floats don't match ints
  {"type.json", 0},
  {"enum.json", 7},
  {"enum.json", 8}
]

omit_tests = []

ExonerateTest.Automate.directory(
  directory2019,
  prefix: D2019,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  draft: "2019-09"
)
