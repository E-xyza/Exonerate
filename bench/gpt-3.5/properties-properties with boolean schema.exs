defmodule :"properties with boolean schema-gpt-3.5" do
  def validate(json) when is_map(json) do
    case Map.fetch(json, "properties") do
      {:ok, properties} ->
        case Map.fetch(properties, "foo") do
          {:ok, true} ->
            case Map.fetch(properties, "bar") do
              {:ok, false} -> :ok
              _ -> :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
