defmodule :"items with boolean schema (true)-gpt-3.5" do
  def validate(object) when is_list(object) do
    case object do
      [_ | _] -> :error
      [] -> :ok
    end
  end

  def validate(object) when is_map(object) do
    case Map.size(object) do
      1 ->
        case Map.keys(object) do
          [:items] ->
            case Map.get(object, :items) do
              true -> :ok
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