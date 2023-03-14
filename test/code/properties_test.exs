defmodule ExonerateTest.Code.ObjectTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Filter.Properties

  describe "tracked properties" do
    test "works" do
      assert_filter(
        quote do
          defp unquote(:"empty#/properties/:tracked")({"foo", value}, path) do
            case unquote(:"empty#/properties/foo")(value, Path.join(path, "foo")) do
              :ok -> {:ok, true}
              Exonerate.Tools.error_match(error) -> error
            end
          end
        end,
        Properties,
        :empty,
        %{"properties" => %{"foo" => %{"const" => []}}},
        tracked: true,
        root: ["properties"]
      )
    end
  end
end
