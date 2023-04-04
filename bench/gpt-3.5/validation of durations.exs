defmodule :"validation of durations-gpt-3.5" do
  defmodule Validator do
    def validate(duration) when is_binary(duration) and is_duration(duration) do
      :ok
    end

    def validate(_) do
      :error
    end

    defp is_duration(duration) do
      case Integer.parse(duration) do
        {int, "ns"} when int >= 0 -> true
        {int, "us"} when int >= 0 -> true
        {int, "ms"} when int >= 0 -> true
        {int, "s"} when int >= 0 -> true
        {int, "m"} when int >= 0 -> true
        {int, "h"} when int >= 0 -> true
        {int, "d"} when int >= 0 -> true
        _ -> false
      end
    end
  end

  defmodule ValidatorTest do
    use ExUnit.Case

    test "valid duration" do
      assert Validator.validate("42s") == :ok
    end

    test "invalid duration" do
      assert Validator.validate("42x") == :error
    end
  end
end
