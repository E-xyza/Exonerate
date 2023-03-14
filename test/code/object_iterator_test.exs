defmodule ExonerateTest.Code.ObjectIteratorTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Object.Iterator

  describe "without the tracked option" do
    test "works with properties" do
      assert_filter(
        quote do
          defp unquote(:"properties#/:iterator")(object, path) do
            Enum.reduce_while(object, :ok, fn
              {key, value}, :ok ->
                with :ok <- unquote(:"properties#/properties")({key, value}, path) do
                  {:cont, :ok}
                else
                  error -> {:halt, error}
                end
            end)
          end
        end,
        Iterator,
        :properties,
        %{"properties" => %{"foo" => %{}}}
      )
    end
  end

  describe "when tracked properties is present, it gets a seen variable" do
    test "works with additionalProperties alone" do
      assert_filter(
        quote do
          defp unquote(:"additional#/:iterator")(object, path) do
            Enum.reduce_while(object, :ok, fn
              _, error = {:error, _} ->
                {:halt, error}

              {key, value}, :ok ->
                visited = false

                with false <- visited,
                     :ok <-
                       unquote(:"additional#/additionalProperties")(value, Path.join(path, key)) do
                  {:cont, :ok}
                else
                  true -> {:cont, :ok}
                  error -> {:halt, error}
                end
            end)
          end
        end,
        Iterator,
        :additional,
        %{"additionalProperties" => %{"const" => true}}
      )
    end

    test "works with patternProperties and additionalProperties" do
      assert_filter(
        quote do
          defp unquote(:"additional#/:iterator")(object, path) do
            Enum.reduce_while(object, :ok, fn
              _, error = {:error, _} ->
                {:halt, error}

              {key, value}, :ok ->
                visited = false

                with {:ok, new_visited} <-
                       unquote(:"additional#/patternProperties/:tracked")({key, value}, path),
                     visited = visited or new_visited,
                     false <- visited,
                     :ok <-
                       unquote(:"additional#/additionalProperties")(value, Path.join(path, key)) do
                  {:cont, :ok}
                else
                  true -> {:cont, :ok}
                  error -> {:halt, error}
                end
            end)
          end
        end,
        Iterator,
        :additional,
        %{
          "additionalProperties" => %{"const" => []},
          "patternProperties" => %{"*" => %{"const" => []}}
        }
      )
    end
  end
end
