defmodule :"content-validation of binary-encoded media type documents with schema-gpt-3.5" do
  def validate(json) when is_binary(json) do
    {:ok, decoded_json} =
      Jason.decode(json,
        keys: :atoms!
      )

    validate(decoded_json)
  end

  def validate(decoded_json) do
    case decoded_json do
      %{
        "contentEncoding" => "base64",
        "contentMediaType" => "application/json",
        "contentSchema" => schema
      } ->
        validate_content_schema(schema)

      _ ->
        :error
    end
  end

  defp validate_content_schema(schema) do
    case schema do
      %{"type" => "object"} ->
        fn object when is_map(object) -> :ok end

      %{"properties" => properties, "required" => required} ->
        fn object when is_map(object) ->
          if Map.has_key?(object, required) && Map.keys(object) -- required == [] do
            :ok
          else
            :error
          end
        end

      _ ->
        fn _ -> :error end
    end
  end
end