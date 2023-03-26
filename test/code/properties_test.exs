defmodule ExonerateTest.Code.PropertiesTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Filter.Properties

  describe "tracked properties" do
    test "works" do
      assert_filter(
        quote do
          defp unquote(:"function://empty/#/properties/:tracked_object")({"foo", value}, path) do
            require Exonerate.Tools

            case unquote(:"function://empty/#/properties/foo")(value, Path.join(path, "foo")) do
              :ok -> {:ok, true}
              Exonerate.Tools.error_match(error) -> error
            end
          end
        end,
        Properties,
        :empty,
        %{"properties" => %{"foo" => %{"const" => []}}},
        tracked: :object,
        root: ["properties"]
      )
    end
  end
end
