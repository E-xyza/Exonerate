format_directory =
  __DIR__
  |> Path.join("_draft2020-12/optional/format")
  |> Path.expand()

omit_modules = ~w(iri-reference.json uri-template.json uri-reference.json regex.json relative-json-pointer.json json-pointer.json iri.json)

omit_describes = []

omit_tests = []

ExonerateTest.Automate.directory(
  format_directory,
  prefix: Format,
  omit_modules: omit_modules,
  omit_describes: omit_describes,
  omit_tests: omit_tests,
  format: true
)
