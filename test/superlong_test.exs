defmodule ExonerateTest.SuperlongTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(:def, :utf8_string, ~s({"type": "string"}))

  Exonerate.function_from_string(
    :def,
    :superlong,
    """
    $id: http://thisisaverylonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglongid/
    properties:
      thisisaverylonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglongkey:
        type: string
      also:
        $ref: http://thisisaverylonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglongid/#properties/thisisaverylonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglonglongkey
    """,
    content_type: "application/yaml"
  )

  test "superlong" do
    assert :ok == superlong(%{"also" => "foo"})
    assert {:error, _} = superlong(%{"also" => 42})
  end
end
