defmodule :"unevaluatedItems-unevaluatedItems with nested tuple-gpt-3.5" do
  def validate(json) do
    case json do
      %{} -> validate_object(json)
      [] -> :ok
      [_ | _] -> validate_array(json)
      _ -> :error
    end
  end

  defp validate_object(json) when is_map(json) do
    :ok
  end

  defp validate_object(_) do
    :error
  end

  defp validate_array(json) when is_list(json) do
    case json do
      [prefix_item | _tail] = json ->
        case prefix_item do
          "string" ->
            case _tail do
              [true | [_ | _rest]] -> validate_array(_rest)
              _ -> :error
            end

          true ->
            case _tail do
              [{"number", _} | [_ | _rest]] -> validate_array(_rest)
              _ -> :error
            end

          _ ->
            :error
        end

      [] ->
        :ok
    end
  end
end
