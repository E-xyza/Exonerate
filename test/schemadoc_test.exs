defmodule ExonerateTest.SchemadocTest do
  use ExUnit.Case, async: true

  test "schemadoc" do
    assert {:docs_v1, 1, :elixir, _, _, _,
      [{{:function, :foo, 1}, _, _, docs, %{}}]} = Code.fetch_docs(ExonerateTest.Docs)

    assert "test doc" in Map.values(docs)
  end
end
