defmodule ExonerateTest.Code.ArrayTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Array

  describe "when the array is not tracked" do
    test "trivial array works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://empty/#/")(array, path) when is_list(array) do
            with do
              :ok
            end
          end
        end,
        Array,
        :empty,
        %{}
      )
    end

    test "when you need an iterator it works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://iterated/#/")(array, path) when is_list(array) do
            with :ok <- unquote(:"exonerate://iterated/#/:array_iterator")(array, path) do
              :ok
            end
          end
        end,
        Array,
        :iterated,
        %{"prefixItems" => [true]}
      )
    end

    test "when you need an combining function it works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://iterated_combining/#/")(array, path) when is_list(array) do
            with :ok <- unquote(:"exonerate://iterated_combining/#/allOf")(array, path),
                 :ok <- unquote(:"exonerate://iterated_combining/#/:array_iterator")(array, path) do
              :ok
            end
          end
        end,
        Array,
        :iterated_combining,
        %{"allOf" => [%{"type" => "array"}], "prefixItems" => [true]}
      )
    end

    test "when you need an combining function and an tracking combining function it works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://tracked_combining/#/")(array, path) when is_list(array) do
            first_unseen_index = 0

            with {:ok, new_index} <-
                   unquote(:"exonerate://tracked_combining/#/allOf/:tracked_array")(array, path),
                 first_unseen_index = max(first_unseen_index, new_index),
                 {:ok, _} <-
                   unquote(:"exonerate://tracked_combining/#/:array_iterator/:tracked_array")(
                     array,
                     path,
                     first_unseen_index
                   ) do
              :ok
            end
          end
        end,
        Array,
        :tracked_combining,
        %{"allOf" => [%{"type" => "array"}], "unevaluatedItems" => [true]}
      )
    end
  end

  describe "when the array is tracked" do
    test "trivial array" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://tracked/#/:tracked_array")(array, path)
               when is_list(array) do
            first_unseen_index = 0

            with do
              {:ok, first_unseen_index}
            end
          end
        end,
        Array,
        :tracked,
        %{},
        tracked: :array
      )
    end

    test "when you need an iterator it works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://tracked_iterated/#/:tracked_array")(array, path)
               when is_list(array) do
            first_unseen_index = 0

            with {:ok, new_index} <-
                   unquote(:"exonerate://tracked_iterated/#/:array_iterator/:tracked_array")(
                     array,
                     path
                   ),
                 first_unseen_index = max(first_unseen_index, new_index) do
              {:ok, first_unseen_index}
            end
          end
        end,
        Array,
        :tracked_iterated,
        %{"prefixItems" => [true]},
        tracked: :array
      )
    end
  end
end
