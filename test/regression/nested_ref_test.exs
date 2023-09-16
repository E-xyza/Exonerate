defmodule ExonerateTest.Regression.NestedRefTest do
  require Exonerate

  # combining an entrypoint with a $ref fails.
  Exonerate.function_from_string(
    :def,
    :ref_trace_entrypoint,
    ~S"""
    schema:
      type: object
      properties:
        bar:
          $ref: '#/one'
    one:
      type: object
      properties:
        foo: 
          $ref: '#/two'
    two:
      type: string
    """,
    encoding: "application/yaml",
    entrypoint: "/schema"
  )
end
