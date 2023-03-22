defmodule ExonerateTest.Code.ArrayTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Array

  describe "when the array is not tracked" do
    test "trivial array works" do
      assert_filter(
        quote do
          defp unquote(:"empty#/")(array, path) when is_list(array) do
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
          defp unquote(:"iterated#/")(array, path) when is_list(array) do
            with :ok <- unquote(:"iterated#/:iterator")(array, path) do
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
          defp unquote(:"iterated#/")(array, path) when is_list(array) do
            with :ok <- unquote(:"iterated#/allOf")(array, path),
                 :ok <- unquote(:"iterated#/:iterator")(array, path) do
              :ok
            end
          end
        end,
        Array,
        :iterated,
        %{"allOf" => [%{"type" => "array"}], "prefixItems" => [true]}
      )
    end

    test "when you need an combining function and an iterator it works" do
      assert_filter(
        quote do
          defp unquote(:"iterated#/")(array, path) when is_list(array) do
            first_unseen_index = 0

            with {:ok, new_index} <-
                   unquote(:"iterated#/allOf/:tracked_array")(array, path),
                 first_unseen_index = max(first_unseen_index, new_index),
                 :ok <-
                   unquote(:"iterated#/:iterator/:tracked_array")(array, path, first_unseen_index) do
              :ok
            end
          end
        end,
        Array,
        :iterated,
        %{"allOf" => [%{"type" => "array"}], "unevaluatedItems" => [true]}
      )
    end
  end

  describe "when the array is tracked" do
    test "trivial array" do
      assert_filter(
        quote do
          defp unquote(:"tracked#/:tracked_array")(array, path) when is_list(array) do
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
          defp unquote(:"tracked_iterated#/:tracked_array")(array, path) when is_list(array) do
            first_unseen_index = 0

            with {:ok, new_index} <-
                   unquote(:"tracked_iterated#/:iterator/:tracked_array")(array, path),
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
