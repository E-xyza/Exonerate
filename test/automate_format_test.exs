format_directory =
  __DIR__
  |> Path.join("_draft2020-12/optional/format")
  |> Path.expand()

omit_modules =
  ~w(iri-reference.json uri-template.json uri-reference.json regex.json relative-json-pointer.json json-pointer.json iri.json)

omit_tests = [
  # elixir's Time admits all of ISO8601, not RFC3339 (as specified by spec)
  {"time.json", {0, 2}},
  # no deep checking of idn-hostname unicode information (for now)
  {"idn-hostname.json", {0, 1}},
  {"idn-hostname.json", {0, 2}},
  {"idn-hostname.json", {0, 11}},
  {"idn-hostname.json", {0, 12}},
  {"idn-hostname.json", {0, 13}},
  {"idn-hostname.json", {0, 16}},
  {"idn-hostname.json", {0, 17}},
  {"idn-hostname.json", {0, 18}},
  {"idn-hostname.json", {0, 19}},
  {"idn-hostname.json", {0, 20}},
  {"idn-hostname.json", {0, 21}},
  {"idn-hostname.json", {0, 23}},
  {"idn-hostname.json", {0, 24}},
  {"idn-hostname.json", {0, 26}},
  {"idn-hostname.json", {0, 27}},
  {"idn-hostname.json", {0, 29}},
  {"idn-hostname.json", {0, 30}},
  {"idn-hostname.json", {0, 32}},
  {"idn-hostname.json", {0, 33}},
  {"idn-hostname.json", {0, 37}},
  {"idn-hostname.json", {0, 40}},
  {"idn-hostname.json", {0, 41}}
]

ExonerateTest.Automate.directory(
  format_directory,
  prefix: Format,
  omit_modules: omit_modules,
  omit_tests: omit_tests,
  format: true
)
