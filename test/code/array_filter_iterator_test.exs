defmodule ExonerateTest.Code.ArrayFilterIteratorTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Array.FilterIterator

  # here are the cases we need to track:
  #
  # logic for tracking.  There are a few cases to deal with:
  # - untracked
  #   - no items/prefixItems
  #     - no additional/unevaluated
  #         trivial
  #     - additional
  #         trivial
  #     - unevaluated, no combining
  #         trivial
  #     - unevaluated, combining
  #         takes three parameters
  #         pass three parameters into unevaluatedParameters
  #   - with items/prefixItems
  #     - items/prefixItems, no additional/unevaluated
  #         trivial
  #     - items/prefixItems, additional
  #         trivial
  #     - prefixItems, with unevaluated, no combining
  #         trivial
  #     - prefixItems, with unevaluated, combining
  #         takes three parameters
  #         pass three parameters into unevaluatedParameters
  #         third parameter should be max(length[prefixitems] and first_unseen_item)
  # - tracked
  #   - no items/prefixItems
  #     - no additional/unevaluated
  #         returns {:ok, 0}
  #     - additional
  #         returns {:ok, index}
  #     - unevaluated, no combining
  #         returns {:ok, 0}
  #     - unevaluated, combining
  #         takes three parameters
  #         pass three parameters into unevaluatedParameters
  #         returns {:ok, index}
  #   - with items/prefixItems
  #     - items/prefixItems, no additional/unevaluated
  #         returns {:ok, min(length(items), index)}
  #     - items/prefixItems, additional
  #         returns {:ok, index}
  #     - prefixItems, with unevaluated, no combining
  #         returns {:ok, index}
  #     - prefixItems, with unevaluated, combining
  #         takes three parameters
  #         pass three parameters into unevaluatedParameters
  #         third parameter should be max(length[prefixitems] and first_unseen_item)
  #         returns {:ok, index}

  describe "without the tracked option" do
    test "no items or prefixItems, no additionalItems/unevaluatedItems" do
      #  no special iteration, just return :ok

      assert_filter(
        quote do
          defp unquote(:"untracked_noitems#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, %{index: 0, so_far: MapSet.new()}}, fn item,
                                                                                  {:ok,
                                                                                   accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_noitems#/uniqueItems")(
                       item,
                       accumulator.so_far,
                       Path.join(path, "#{accumulator.index}")
                     ) do
                {:cont,
                 {:ok,
                  %{
                    accumulator
                    | index: accumulator.index + 1,
                      so_far: MapSet.put(accumulator.so_far, item)
                  }}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> elem(0)
          end
        end,
        FilterIterator,
        :untracked_noitems,
        %{"uniqueItems" => true}
      )
    end

    test "no items or prefixItems, with additionalItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"untracked_prefix_items#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_prefix_items#/additionalItems/:entrypoint")(
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
        :untracked_prefix_items,
        %{"additionalItems" => %{type: "string"}}
      )
    end

    test "no prefixItems, with unevaluatedItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"untracked_no_prefix_items_unevaluatedItems#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(
                       :"untracked_no_prefix_items_unevaluatedItems#/unevaluatedItems/:entrypoint"
                     )(
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
        :untracked_no_prefix_items_unevaluatedItems,
        %{"unevaluatedItems" => %{type: "string"}}
      )
    end

    test "no prefixItems, with unevaluatedItems and combining filters" do
      # needs three parameters.
      # include the last index in the entrypoint tuple
      assert_filter(
        quote do
          defp unquote(:"untracked_no_prefix_items_unevaluatedItems#/:iterator")(
                 array,
                 path,
                 first_unseen_index
               ) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(
                       :"untracked_no_prefix_items_unevaluatedItems#/unevaluatedItems/:entrypoint"
                     )(
                       {item, accumulator, first_unseen_index},
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
        :untracked_no_prefix_items_unevaluatedItems,
        %{"unevaluatedItems" => %{type: "string"}, "allOf" => []}
      )
    end

    test "with prefixItems, no additionalItems or unevaluatedItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"untracked_prefix_items#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_prefix_items#/prefixItems")(
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
        :untracked_prefix_items,
        %{"prefixItems" => [true]}
      )
    end

    test "with prefixItems, with additionalItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"untracked_prefix_items_additional#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_prefix_items_additional#/additionalItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"untracked_prefix_items_additional#/prefixItems")(
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
        :untracked_prefix_items_additional,
        %{"prefixItems" => [true], "additionalItems" => %{type: "string"}}
      )
    end

    test "with prefixItems, with unevaluatedItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"untracked_prefix_items_unevaluated#/:iterator")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_prefix_items_unevaluated#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"untracked_prefix_items_unevaluated#/unevaluatedItems/:entrypoint")(
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
        :untracked_prefix_items_unevaluated,
        %{"prefixItems" => [true], "unevaluatedItems" => %{type: "string"}}
      )
    end

    test "with prefixItems, with unevaluatedItems and combining filters" do
      #  no special iteration, just return {:ok, 0}
      assert_filter(
        quote do
          defp unquote(:"untracked_prefix_items_unevaluated_combining#/:iterator")(
                 array,
                 path,
                 first_unseen_index
               ) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"untracked_prefix_items_unevaluated_combining#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(
                       :"untracked_prefix_items_unevaluated_combining#/unevaluatedItems/:entrypoint"
                     )(
                       {item, accumulator, max(first_unseen_index, 1)},
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
        :untracked_prefix_items_unevaluated_combining,
        %{"prefixItems" => [true], "unevaluatedItems" => %{type: "string"}, "allOf" => []}
      )
    end
  end

  describe "with the tracked option" do
    test "no items or prefixItems, no additionalItems/unevaluatedItems" do
      #  returns {:ok, 0}

      assert_filter(
        quote do
          defp unquote(:"tracked_noitems#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, %{index: 0, so_far: MapSet.new()}}, fn item,
                                                                                  {:ok,
                                                                                   accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_noitems#/uniqueItems")(
                       item,
                       accumulator.so_far,
                       Path.join(path, "#{accumulator.index}")
                     ) do
                {:cont,
                 {:ok,
                  %{
                    accumulator
                    | index: accumulator.index + 1,
                      so_far: MapSet.put(accumulator.so_far, item)
                  }}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} ->
                {:ok, 0}

              {error} ->
                error
            end
          end
        end,
        FilterIterator,
        :tracked_noitems,
        %{"uniqueItems" => true},
        tracked: :array
      )
    end

    test "no items or prefixItems, with additionalItems" do
      #  returns {:ok, index}
      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_prefix_items#/additionalItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items,
        %{"additionalItems" => %{type: "string"}},
        tracked: :array
      )
    end

    test "no prefixItems, with unevaluatedItems" do
      #  no special iteration, just return :ok
      assert_filter(
        quote do
          defp unquote(:"tracked_no_prefix_items_unevaluatedItems#/:iterator/:tracked_array")(
                 array,
                 path
               ) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(
                       :"tracked_no_prefix_items_unevaluatedItems#/unevaluatedItems/:entrypoint/:tracked_array"
                     )(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_no_prefix_items_unevaluatedItems,
        %{"unevaluatedItems" => %{type: "string"}},
        tracked: :array
      )
    end

    test "no prefixItems, with unevaluatedItems and combining filters" do
      # needs three parameters.
      # include the last index in the entrypoint tuple
      assert_filter(
        quote do
          defp unquote(:"tracked_no_prefix_items_unevaluatedItems#/:iterator/:tracked_array")(
                 array,
                 path,
                 first_unseen_index
               ) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(
                       :"tracked_no_prefix_items_unevaluatedItems#/unevaluatedItems/:entrypoint/:tracked_array"
                     )(
                       {item, accumulator, first_unseen_index},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_no_prefix_items_unevaluatedItems,
        %{"unevaluatedItems" => %{type: "string"}, "allOf" => []},
        tracked: :array
      )
    end

    test "with prefixItems, no additionalItems or unevaluatedItems" do
      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_prefix_items#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, min(accumulator, 1)}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items,
        %{"prefixItems" => [true]},
        tracked: :array
      )
    end

    test "with prefixItems, with additionalItems" do
      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items_additional#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_prefix_items_additional#/additionalItems/:entrypoint")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"tracked_prefix_items_additional#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items_additional,
        %{"prefixItems" => [true], "additionalItems" => %{type: "string"}},
        tracked: :array
      )
    end

    test "with prefixItems, with items" do
      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items_items#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(
                       :"tracked_prefix_items_items#/items/:entrypoint"
                     )(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(:"tracked_prefix_items_items#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items_items,
        %{"prefixItems" => [true], "items" => %{type: "string"}},
        tracked: :array
      )
    end

    test "with prefixItems, with unevaluatedItems" do
      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items_unevaluated#/:iterator/:tracked_array")(array, path) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_prefix_items_unevaluated#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(
                       :"tracked_prefix_items_unevaluated#/unevaluatedItems/:entrypoint/:tracked_array"
                     )(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items_unevaluated,
        %{"prefixItems" => [true], "unevaluatedItems" => %{type: "string"}},
        tracked: :array
      )
    end

    test "with prefixItems, with unevaluatedItems and combining filters" do
      #         takes three parameters
      #         pass three parameters into unevaluatedParameters
      #         third parameter should be max(length[prefixitems] and first_unseen_item)
      #         returns {:ok, index}

      assert_filter(
        quote do
          defp unquote(:"tracked_prefix_items_unevaluated_combining#/:iterator/:tracked_array")(
                 array,
                 path,
                 first_unseen_index
               ) do
            Enum.reduce_while(array, {:ok, 0}, fn item, {:ok, accumulator} ->
              require Exonerate.Tools

              with :ok <-
                     unquote(:"tracked_prefix_items_unevaluated_combining#/prefixItems")(
                       {item, accumulator},
                       Path.join(path, "#{accumulator}")
                     ),
                   :ok <-
                     unquote(
                       :"tracked_prefix_items_unevaluated_combining#/unevaluatedItems/:entrypoint/:tracked_array"
                     )(
                       {item, accumulator, max(first_unseen_index, 1)},
                       Path.join(path, "#{accumulator}")
                     ) do
                {:cont, {:ok, accumulator + 1}}
              else
                Exonerate.Tools.error_match(error) -> {:halt, {error}}
              end
            end)
            |> case do
              {:ok, accumulator} -> {:ok, accumulator}
              {error} -> error
            end
          end
        end,
        FilterIterator,
        :tracked_prefix_items_unevaluated_combining,
        %{"prefixItems" => [true], "unevaluatedItems" => %{type: "string"}, "allOf" => []},
        tracked: :array
      )
    end
  end
end
