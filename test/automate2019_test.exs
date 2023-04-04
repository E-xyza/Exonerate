directory2019 =
  __DIR__
  |> Path.join("_draft2019-09")
  |> Path.expand()

omit_modules = ~w(anchor.json dynamicRef.json defs.json id.json)

omit_describes = [
  # references the openAPI schema document, which contains currently unparseable filters.
  {"ref.json", 6},
  # no floating point multiples
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  {"refRemote.json", 4}
]

omit_tests = [
  # integer filters do not match float values:
  {"type.json", {0, 1}},
  {"enum.json", {7, 2}},
  {"enum.json", {8, 2}}
]

ExonerateTest.Automate.directory(
  directory2019,
  prefix: D2019,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  draft: "2019-09",
  proxy: [{"http://localhost:1234", "http://localhost:1234/_draft2019-09/remotes"}],
  force_remote: true,
  cache: false
)
