defmodule :"content-validation of binary-encoded media type documents-gpt-3.5" do
  def validate(value) when is_map(value) do
    case value do
      %{"contentEncoding" => "base64", "contentMediaType" => "application/json"} ->
        :ok

      %{"type" => "object"} ->
        :ok

      %{"type" => "string"} ->
        :ok

      %{"type" => "number"} ->
        :ok

      %{"type" => "integer"} ->
        :ok

      %{"type" => "boolean"} ->
        :ok

      %{"type" => "null"} ->
        :ok

      %{"type" => "array", "items" => schema} ->
        case validate(schema) do
          :ok -> :ok
          _ -> :error
        end

      %{"type" => "object", "properties" => properties} ->
        case validate_properties(properties) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  def validate_properties(properties) do
    Enum.reduce(properties, :ok, fn {_, schema}, acc ->
      case acc do
        :error ->
          :error

        _ ->
          case validate(schema) do
            :ok -> acc
            _ -> :error
          end
      end
    end)
  end
end
