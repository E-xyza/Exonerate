defmodule ExonerateTest.Code.ArrayFilterIteratorTest do
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

              with :ok <-
                     unquote(:"items#/items")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
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

  describe "tracked items is put in the queue normally" do
    test "works with additionalItems" do
      assert_filter(
        quote do
          defp unquote(:"additional#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"additional#/additionalItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :additional,
        %{"additionalItems" => %{"const" => true}}
      )
    end

    test "works with additionalItems and array items" do
      assert_filter(
        quote do
          defp unquote(:"additional#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"additional#/additionalItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"additional#/items")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :additional,
        %{"items" => [true], "additionalItems" => %{"const" => true}}
      )
    end

    test "works with unevaluatedItems" do
      assert_filter(
        quote do
          defp unquote(:"unevaluated#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"unevaluated#/unevaluatedItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :unevaluated,
        %{"unevaluatedItems" => %{"const" => true}}
      )
    end

    test "works with unevaluatedItems and array items" do
      assert_filter(
        quote do
          defp unquote(:"unevaluated#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"unevaluated#/items")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"unevaluated#/unevaluatedItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :unevaluated,
        %{"items" => [true], "unevaluatedItems" => %{"const" => true}}
      )
    end
  end
end
