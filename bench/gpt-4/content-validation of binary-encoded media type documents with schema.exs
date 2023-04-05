defmodule :"validation of binary-encoded media type documents with schema" do
  def validate(%{"contentEncoding" => "base64", "contentMediaType" => "application/json", "contentSchema" => schema} = object) do
    case Jason.decode!(Base.decode64!(object)) do
      %{"foo" => _} = json ->
        if validate_object(json, schema) do
          :ok
        else
          :error
        end
      _ ->
        :error
    end
  end

  def validate(_), do: :error

  defp validate_object(object, schema) when is_map(object) and is_map(schema) do
    required_fields = Map.get(schema, "required", [])
    for field <- required_fields, not Map.has_key?(object, field) do
      return false
    end

    properties = Map.get(schema, "properties", %{})
    for {key, value} <- properties do
      case Map.has_key?(object, key) do
        true ->
          case value do
            %{"type" => "string"} ->
              if is_binary(Map.get(object, key)) do
                :ok
              else
                return false
              end
            _ ->
              # Unsupported schema
              return false
          end
        false ->
          return false
      end
    end

    true
  end
  defp validate_object(_, _), do: false
end
