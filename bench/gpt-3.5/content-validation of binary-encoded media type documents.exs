defmodule :"validation of binary-encoded media type documents-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object["contentEncoding"] do
      "base64" ->
        case object["contentMediaType"] do
          "application/json" ->
            case object["decoded_value"] do
              %{"type" => "object"} -> :ok
              %{"type" => "array"} -> :ok
              %{"type" => "string"} -> :ok
              %{"type" => "integer"} -> :ok
              %{"type" => "number"} -> :ok
              %{"type" => "boolean"} -> :ok
              %{"type" => "null"} -> :ok
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