defmodule ExonerateTest.RefNotFoundTest do
  use ExUnit.Case, async: true

  @error_string if Version.compare(Version.parse!(System.version()), %Version{major: 1, minor: 15, patch: 0}) == :lt do
    " reference points to: #/definitions/foo, this location not found in the schema"
  else
    "reference points to: #/definitions/foo, this location not found in the schema"
  end

  test "if there's a missing ref, we get a CompileError" do
    assert_raise CompileError,
                 @error_string,
                 fn ->
                   __DIR__
                   |> Path.join("ref_not_found_root.exs")
                   |> Code.compile_file()
                 end
  end
end
