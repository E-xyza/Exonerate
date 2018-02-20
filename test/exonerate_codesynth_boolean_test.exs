defmodule ExonerateCodesynthBooleanNilTest do
  use ExUnit.Case, async: true
  import ExonerateTest.Helper

  @moduledoc """
    some basic tests to ensure that code generated for booleans and nils looks sane.
  """

  @tag :exonerate_codesynth
  test "boolean json true is always valid" do
    codesynth_match(true, "def validate_test(val), do: :ok")
  end

  @tag :exonerate_codesynth
  test "boolean json false is always an error" do
    codesynth_match(
      false,
      "def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}"
    )
  end

  @tag :exonerate_codesynth
  test "nil json schemas generate correct code" do
    codesynth_match(%{"type" => "null"}, """
      def validate_test(nil), do: :ok
      def validate_test(val), do: {:error, \"\#{Poison.encode! val} does not conform to JSON schema\"}
    """)
  end
end
