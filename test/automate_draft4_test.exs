directory_draft4 =
  __DIR__
  |> Path.join("_draft4")
  |> Path.expand()

omit_modules = ~w(refRemote.json definitions.json)

omit_describes = [
  # no support for relative uri (for now)
  {"ref.json", 6},
  {"ref.json", 11},
  {"ref.json", 12},
  {"ref.json", 13},
  # no floating point multiples
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3}
]

omit_tests = [
  # integer filters do not match float values:
  {"type.json", {0, 1}},
  {"enum.json", {7, 2}},
  {"enum.json", {8, 2}}
]

ExonerateTest.Automate.directory(
  directory_draft4,
  prefix: Draft4,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  draft: "4"
)
