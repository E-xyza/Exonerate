defmodule ExonerateTest.Code.ObjectTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Object

  describe "trivial object" do
    test "works" do
      assert_filter(
        quote do
          defp unquote(:"exonerate://empty/#/")(object, path) when is_map(object) do
            with do
              :ok
            end
          end
        end,
        Object,
        :empty,
        %{}
      )
    end
  end
end
