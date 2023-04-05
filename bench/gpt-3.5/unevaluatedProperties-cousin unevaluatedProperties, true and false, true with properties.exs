defmodule :"cousin unevaluatedProperties, true and false, true with properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_schema(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_schema(schema) when is_map(schema) do
    case schema["type"] do
      "object" ->
        case schema["allOf"] do
          [first | _] ->
            case Map.keys(first) do
              ["properties"] ->
                case first["properties"] do
                  props when is_map(props) ->
                    if schema["unevaluatedProperties"] do
                      :ok
                    else
                      :error
                    end

                  _ ->
                    :error
                end

              "unevaluatedProperties" ->
                if first["unevaluatedProperties"] do
                  case schema["unevaluatedProperties"] do
                    true -> :ok
                    _ -> :error
                  end
                else
                  :error
                end

              _ ->
                :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end
end