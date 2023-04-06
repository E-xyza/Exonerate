defmodule :"unevaluatedProperties-unevaluatedProperties with adjacent patternProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    %{"patternProperties" => pattern_props, "type" => type} = schema()
    case type do
      "object" ->
        Enum.all?(Map.keys(object), fn key ->
          Enum.any?([pattern | _], Map.keys(pattern_props), &String.match?(^&, key)) and
            Map.get(schema(), "unevaluatedProperties") == false
        end) and :ok or :error
      _ -> :error
    end
  end

  def validate(_), do: :error

  defp schema() do
    %{
      "patternProperties" => %{"^foo" => %{"type" => "string"}},
      "type" => "object",
      "unevaluatedProperties" => false
    }
  end
end
