defmodule ExonerateTest.Macro.Helpers.BuildCondTest do

  use ExUnit.Case

  alias Exonerate.BuildCond

  test "an empty buildcond builds a null result" do

    nilquote = quote do :ok end

    assert nilquote == BuildCond.build([])
  end

  test "a single value to buildcond builds the expected single thing" do

    test1 = quote do test == 1 end
    resp1 = quote do :works end

    result = quote do
      cond do
        test == 1 -> :works
        true -> :ok
      end
    end

    assert result == BuildCond.build([{test1, resp1}])
  end

  test "multiple values to buildcond builds the expected single thing" do

    test1 = quote do test == 1 end
    resp1 = quote do :works end

    test2 = quote do test == 2 end
    resp2 = quote do test + 3 end

    result = quote do
      cond do
        test == 1 -> :works
        test == 2 -> test + 3
        true -> :ok
      end
    end

    assert result == BuildCond.build([{test1, resp1}, {test2, resp2}])
  end

end
