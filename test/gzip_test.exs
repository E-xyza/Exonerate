defmodule ExonerateTest.GzipTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_file(:defp, :compressed, "test/assets/compressed.json.gz")

  describe "gzip compressed schemas" do
    test "can load .json.gz files" do
      assert :ok = compressed("hello")
      assert {:error, _} = compressed(42)
    end
  end
end
