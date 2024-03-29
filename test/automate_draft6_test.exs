directory_draft6 =
  __DIR__
  |> Path.join("_draft6")
  |> Path.expand()

omit_modules =
  ~w(refRemote.json definitions.json) ++ Application.get_env(:exonerate, :omit_modules, [])

omit_describes = [
  # references the openAPI schema document, which contains currently unparseable filters.
  {"ref.json", 6},
  {"ref.json", 13},
  {"ref.json", 14},
  {"ref.json", 15},
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
  directory_draft6,
  prefix: Draft6,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  draft: "6"
)
