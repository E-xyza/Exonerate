directory_draft4 =
  __DIR__
  |> Path.join("_draft4")
  |> Path.expand()

omit_modules =
  ~w(refRemote.json definitions.json ref.json infinite-loop-detection.json items.json)

omit_describes = [
  # no support for relative uri (for now)
  {"ref.json", 6},
  {"ref.json", 12},
  {"ref.json", 13},
  # no support for definitions
  {"ref.json", 9},
  {"ref.json", 11},
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
  directory_draft4,
  prefix: Draft4,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  draft: "4"
)
