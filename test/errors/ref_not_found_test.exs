defmodule ExonerateTest.RefNotFoundTest do
  use ExUnit.Case, async: true

  test "if there's a missing ref, we get a CompileError" do
    assert_raise CompileError,
                 "reference points to: #/definitions/foo, this location not found in the schema",
                 fn ->
                   __DIR__
                   |> Path.join("ref_not_found_root.exs")
                   |> Code.compile_file()
                 end
  end
end
