defmodule ExonerateTest.PublicTest do

  # public/private scoping test

  use ExUnit.Case

  defmodule TestSchema do

    import Exonerate

    defschema test: """
    {
      "type": "object",
      "properties": {
        "number": {
          "type": "number",
          "description": "stores a number"
        }
      }
    }
    """
  end

  test "schema works as advertised" do
    assert :ok = TestSchema.test(%{"number" => 1})
    refute :ok == TestSchema.test(%{"number" => "one"})
  end

  test "metadata makes the subvalue a public function" do
    assert "stores a number" == TestSchema.test__properties__number(:description)
  end

end
