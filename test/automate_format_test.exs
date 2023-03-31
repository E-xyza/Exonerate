format_directory =
  __DIR__
  |> Path.join("_draft2020-12/optional/format")
  |> Path.expand()

omit_modules = ~w(iri-reference.json uri-template.json uri-reference.json regex.json relative-json-pointer.json json-pointer.json iri.json)

ExonerateTest.Automate.directory(
  format_directory,
  prefix: Format,
  omit_modules: omit_modules,
  format: true
)
