defmodule ExonerateTest.Code.ArrayIteratorTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Array.FilterIterator

  describe "without the tracked option" do
    test "works with items" do
      assert_filter(
        quote do
          defp unquote(:"items#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools
              with :ok <- unquote(:"items#/items")({item, accumulator}, Path.join(path, "#{accumulator}")) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :items,
        %{"items" => [%{"type" => "string"}]}
      )
    end
  end
end
