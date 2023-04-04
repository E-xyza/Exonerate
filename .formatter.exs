# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  # some files in gpt-3.5 have syntax errors.
  subdirectories: ["bench"]
]
