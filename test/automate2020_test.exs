directory2020 =
  __DIR__
  |> Path.join("_draft2020-12")
  |> Path.expand()

omit_modules = ~w(defs.json anchor.json dynamicRef.json id.json infinite-loop-detection.json
refRemote.json unevaluatedProperties.json items.json ref.json unevaluatedItems.json)

omit_describes = [
  # integer filters do not match float values:
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  # no support for dynamicRef
  {"ref.json", 6},
  {"ref.json", 1},
  {"ref.json", 2},
  {"ref.json", 3},
  {"ref.json", 4},
  {"ref.json", 5},
  {"ref.json", 7},
  {"ref.json", 8},
  {"ref.json", 9},
  {"ref.json", 10},
  {"ref.json", 11},
  {"ref.json", 12},
  # these are more than just annotations, and are tested in test.
  {"format.json", 3},
  {"format.json", 4},
  {"format.json", 7},
  {"format.json", 8},
  {"format.json", 9},
  {"format.json", 17}
]

omit_tests = [
  # integer filters do not match float values:
  {"type.json", {0, 1}},
  {"enum.json", {7, 2}},
  {"enum.json", {8, 2}}
]

ExonerateTest.Automate.directory(
  directory2020,
  prefix: D2020,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests
)
