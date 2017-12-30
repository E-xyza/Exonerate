defmodule ExonerateTest.Helper do

  @moduledoc """
    provides a helper macro that makes the testing suites much simpler
  """

  defmacro codesynth_match(map, code) do
    quote do
      get_route = unquote(map)
      get_code = unquote(code) |> Code.format_string!() |> Enum.join()

      test_code =
        Exonerate.Codesynth.validator_string("test", get_route) |> Code.format_string!()
        |> Enum.join()

      assert test_code == get_code
    end
  end
end
