defmodule :"content-validation of string-encoded content based on media type-gpt-3.5" do
  defmodule Validator do
    def validate(object) when is_map(object) do
      :ok
    end

    def validate(_) do
      :error
    end

    def validate_jsonschema(schema, data) do
      case schema do
        %{"type" => "object"} ->
          if is_map(data) do
            :ok
          else
            :error
          end

        %{"type" => "array"} ->
          if is_list(data) do
            :ok
          else
            :error
          end

        %{"type" => "string"} ->
          if is_binary(data) do
            :ok
          else
            :error
          end

        %{"type" => "number"} ->
          if is_number(data) do
            :ok
          else
            :error
          end

        %{"type" => "boolean"} ->
          if is_boolean(data) do
            :ok
          else
            :error
          end

        %{"contentMediaType" => "application/json"} ->
          case Jason.decode(data) do
            {:ok, _} -> :ok
            {:error, _} -> :error
          end

        _ ->
          :error
      end
    end
  end

  data = "{\"name\": \"John Doe\", \"age\": 30}"
  schema = %{"type" => "object"}
  Validator.validate_jsonschema(schema, data)
end
