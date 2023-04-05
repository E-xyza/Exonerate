defmodule :"const with object-gpt-3.5" do
  def validate(object) when is_map(object) do
    {:ok, _} =
      Matcher.match(
        object,
        %{"const" => %{"baz" => "bax", "foo" => "bar"}}
      )

    :ok
  end

  def validate(_) do
    :error
  end

  defp type_matcher("object") do
    %{type: "map"}
  end

  defp type_matcher(_) do
    %{type: "unknown"}
  end

  defp const_matcher(const) do
    %{const: const}
  end

  defp const_matcher(_) do
    %{const: nil}
  end

  defp object_validator(%{"type" => type}) do
    %{type: t} = type_matcher(type)

    fn
      object when t -> :ok
      object -> :error
    end
  end

  defp object_validator(%{"const" => obj}) do
    %{const: c} = const_matcher(obj)

    fn
      object when object == c -> :ok
      _ -> :error
    end
  end

  defp object_validator(_) do
    & &1
  end
end