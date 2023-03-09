defmodule Benchmark do
  @schema_str """
  {
    "properties": {
        "foo\\"bar": {"$ref": "#/definitions/foo%22bar"}
    },
    "definitions": {
        "foo\\"bar": {"type": "number"}
    }
  }
  """

  @schema Jason.decode!(@schema_str)

  @test %{"foo\"bar" => "1"}

  require Exonerate
  Exonerate.function_from_string(:defp, :go, """
  {
    "properties": {
        "foo\\"bar": {"$ref": "#/definitions/foo%22bar"}
    },
    "definitions": {
        "foo\\"bar": {"type": "number"}
    }
  }
  """)

  def run do
    Benchee.run(%{
      "Exonerate" => fn -> go(@test) end,
      "ExJsonSchema" => fn -> ExJsonSchema.Validator.validate(@schema, @test) end
    })
  end
end
