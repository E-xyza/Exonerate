defmodule ExonerateCodesynthSpecificTest do
  use ExUnit.Case, async: true
  import ExonerateTest.Helper

  @moduledoc """
    specific json schema testing that came about during comprehensive validation.
  """

  @tag :exonerate_codesynth
  test "json schemas that don't specify array with array parameters build properly" do
    codesynth_match(%{"items" => [%{}], "additionalItems" => %{"type" => "integer"}}, """
    def validate_test__additionalItems(val) when is_integer(val), do: :ok
    def validate_test__additionalItems(val), do: {:error, "\#{Jason.encode! val} does not conform to JSON schema"}

    def validate_test_0(val), do: :ok

    def validate_test__all(val) do
      Exonerate.Checkers.check_additionalitems(val, [&__MODULE__.validate_test_0/1], &__MODULE__.validate_test__additionalItems/1)
    end

    def validate_test(val) when is_list(val), do: validate_test__all(val)
    def validate_test(val), do: :ok
    """)
  end

end
