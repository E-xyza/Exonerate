defmodule ExonerateTest.Code.ArrayTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Array

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
          saw_prior_to = 0
          with {:ok, new_saw_prior_to} <- unquote(:"iterated#/allOf/:tracked")(array, path),
               saw_prior_to = max(saw_prior_to, new_saw_prior_to),
               :ok <- unquote(:"iterated#/:iterator/:tracked")(array, path, saw_prior_to) do
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
