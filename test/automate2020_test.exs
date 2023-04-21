directory2020 =
  __DIR__
  |> Path.join("_draft2020-12")
  |> Path.expand()

omit_modules =
  ~w(defs.json anchor.json dynamicRef.json id.json) ++
    Application.get_env(:exonerate, :omit_modules)

omit_describes = [
  # integer filters do not match float values:
  {"multipleOf.json", 1},
  {"multipleOf.json", 2},
  {"multipleOf.json", 3},
  # references the openAPI schema document, which contains currently unparseable filters.
  {"ref.json", 6},
  {"refRemote.json", 4}
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
