defmodule ExonerateTest.Draft7Test do
  use ExUnit.Case, async: true
  require Exonerate

  @array [1, 2, 3]

  Exonerate.function_from_string(:defp, :draft7, """
  {
      "definitions": {
          "reffed": {
              "type": "array"
          }
      },
      "properties": {
          "foo": {
              "$ref": "#/definitions/reffed",
              "maxItems": 2
          }
      }
  }
  """, draft: "7")

  test "draft-7" do
    assert :ok = draft7(%{"foo" => @array})
  end

#  Exonerate.function_from_string(:defp, :draft2020, """
#  {
#      "definitions": {
#          "reffed": {
#              "type": "array"
#          }
#      },
#      "properties": {
#          "foo": {
#              "$ref": "#/definitions/reffed",
#              "maxItems": 2
#          }
#      }
#  }
#  """, draft: "2020")
#
#  test "draft-2020" do
#    assert {:error, _} = draft2020(%{"foo" => @array})
#  end
end
