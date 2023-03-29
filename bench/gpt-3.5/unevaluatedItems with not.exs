defmodule :"unevaluatedItems with not-gpt-3.5" do
  def validate(json) when is_list(json) do
    check_array(json)
  end

  def validate(json) when is_map(json) do
    check_object(json)
  end

  def validate(_) do
    :error
  end

  defp check_array(json) do
    case Keyword.fetch(json, "type") do
      {:ok, "array"} ->
        items = Keyword.get(json, "prefixItems", [])
        eval_items = Keyword.get(json, "unevaluatedItems", "true")

        if !Enum.all?(items, fn item ->
             case Keyword.fetch(item, "const") do
               {:ok, const} -> const in [true, false]
               :error -> false
             end
           end) do
          :error
        else
          :ok
        end

      _ ->
        :error
    end
  end

  defp check_object(json) do
    case Keyword.fetch(json, "type") do
      {:ok, "object"} -> :ok
      _ -> :error
    end
  end
end
