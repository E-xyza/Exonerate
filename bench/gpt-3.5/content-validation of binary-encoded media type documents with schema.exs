defmodule :"validation of binary-encoded media type documents with schema-gpt-3.5" do
  def validate(decoded_json) do
    case :jiffy.decode(decoded_json) do
      {:ok, json_doc} ->
        schema = %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}

        case validate_doc(json_doc, schema) do
          true -> :ok
          false -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_doc(doc, schema) when is_map(doc) and is_map(schema) do
    Map.keys(schema["properties"]) -- Map.keys(doc) == [] and
      schema["required"] -- Map.keys(doc) == []
  end

  defp validate_doc(_doc, %{"type" => "object"}) do
    true
  end

  defp validate_doc(_doc, _schema) do
    false
  end
end