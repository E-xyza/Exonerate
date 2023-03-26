directory2020 =
  __DIR__
  |> Path.join("_draft2020-12")
  |> Path.expand()

omit_modules = ~w(defs.json anchor.json dynamicRef.json id.json)

omit_describes = [
  # integer filters do not match float values:
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  # references the openAPI schema document, which contains currently unparseable filters.
  {"ref.json", 6},
  {"ref.json", 11},
  # these are more than just annotations, and are tested in test.
  {"format.json", 3},
  {"format.json", 4},
  {"format.json", 7},
  {"format.json", 8},
  {"format.json", 9},
  {"format.json", 17},
  {"refRemote.json", 3},
  {"refRemote.json", 4},
  {"refRemote.json", 5},
  {"refRemote.json", 6}
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
  omit_tests: omit_tests,
  proxy: [{"http://localhost:1234", "http://localhost:1234/_draft2020-12/remotes"}],
  force_remote: true,
  cache: false
)
