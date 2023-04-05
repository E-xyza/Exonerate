defmodule :"unevaluatedProperties with nested patternProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) -- [:foo] do
      [] ->
        case Map.fetch(object, :foo) do
          {:ok, value} when is_binary(value) -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end