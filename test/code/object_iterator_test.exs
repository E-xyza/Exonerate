defmodule ExonerateTest.Code.ObjectIteratorTest do
  use ExUnit.Case, async: true
  import ExonerateTest.CodeCase

  alias Exonerate.Type.Object.Iterator

  describe "without the tracked option" do
    test "works with properties" do
      assert_filter(
        quote do
          defp unquote(:"properties#/:iterator")(object, path) do
            require Exonerate.Tools

            Enum.reduce_while(object, :ok, fn
              {key, value}, :ok ->
                with :ok <- unquote(:"properties#/properties")({key, value}, path) do
                  {:cont, :ok}
                else
                  Exonerate.Tools.error_match(error) -> {:halt, error}
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
            require Exonerate.Tools

            Enum.reduce_while(object, :ok, fn
              {key, value}, :ok ->
                visited = false

                with false <- visited do
                  {:cont, unquote(:"additional#/additionalProperties")(value, Path.join(path, key))}
                else
                  true -> {:cont, :ok}
                  Exonerate.Tools.error_match(error) -> {:halt, error}
                end

              _, Exonerate.Tools.error_match(error) ->
                {:halt, error}
            end)
            |> case do
              result -> result
            end
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
            require Exonerate.Tools

            Enum.reduce_while(object, :ok, fn
              {key, value}, :ok ->
                visited = false

                with {:ok, new_visited} <-
                       unquote(:"additional#/patternProperties/:tracked_object")(
                         {key, value},
                         path
                       ),
                     visited = visited or new_visited,
                     false <- visited do
                  {:cont, unquote(:"additional#/additionalProperties")(value, Path.join(path, key))}
                else
                  true -> {:cont, :ok}
                  Exonerate.Tools.error_match(error) -> {:halt, error}
                end

              _, Exonerate.Tools.error_match(error) ->
                {:halt, error}
            end)
            |> case do
              result -> result
            end
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
