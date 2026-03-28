defmodule ExonerateTest.RefNotFoundRoot do
  require Exonerate

  Exonerate.function_from_string(
    :defp,
    :yaml,
    """
    type: object
    parameters:
      foo:
        $ref: "#/definitions/foo"
    """,
    content_type: "application/yaml"
  )
end
