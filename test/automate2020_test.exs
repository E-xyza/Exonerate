directory2020 =
  __DIR__
  |> Path.join("_draft2020-12")
  |> Path.expand()

omit_modules = ~w(defs.json anchor.json dynamicRef.json id.json infinite-loop-detection.json
refRemote.json unevaluatedItems.json)

omit_describes = [
  # integer filters do not match float values:
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  # no support for external uri's
  {"ref.json", 6},
  # no support for relative uri (for now)
  {"ref.json", 11},
  # currently no support for unevaluated
  {"ref.json", 13},
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
  {"type.json", 0, 1},
  {"enum.json", 7, 2},
  {"enum.json", 8, 2}
]

ExonerateTest.Automate.directory(
  directory2020,
  prefix: D2020,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests
)
