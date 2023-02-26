defmodule ExonerateTest.Draft.Draft4ExclusiveTest do
  use ExUnit.Case, async: true

  require Exonerate

  Exonerate.function_from_string(
    :def,
    :min_excl_false,
    ~s({"minimum": 1, "exclusiveMinimum": false})
  )

  Exonerate.function_from_string(
    :def,
    :min_excl_true,
    ~s({"minimum": 1, "exclusiveMinimum": true})
  )

  Exonerate.function_from_string(
    :def,
    :max_excl_false,
    ~s({"maximum": 1, "exclusiveMaximum": false})
  )

  Exonerate.function_from_string(
    :def,
    :max_excl_true,
    ~s({"maximum": 1, "exclusiveMaximum": true})
  )

  test "exclusive minimum" do
    assert :ok = min_excl_false(1)
    assert {:error, _list} = min_excl_true(1)
  end

  test "exclusive maximum" do
    assert :ok = max_excl_false(1)
    assert {:error, _list} = max_excl_true(1)
  end
end
