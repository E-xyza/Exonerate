defmodule :"patternProperties-patternProperties validates properties matching a regex-gpt-3.5" do
  def validate(schema) do
    case schema do
      %{"patternProperties" => pattern_properties} ->
        pattern_keys = Map.keys(pattern_properties)

        Enum.reduce(pattern_keys, :ok, fn key, acc ->
          clause =
            quote do
              is_integer(unquote(:object[unquote(key)]))
            end

          if Map.has_key?(pattern_properties, key) and not clause do
            {:error, "Validation Failed"}
          else
            acc
          end
        end)

      %{"type" => "object"} ->
        quote do
          def validate(object) when is_map(object) do
            :ok
          end

          def validate(_) do
            :error
          end
        end

      _ ->
        {:error, "Invalid schema"}
    end
  end
end
