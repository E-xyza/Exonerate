defmodule :"unevaluatedItems can't see inside cousins-gpt-3.5" do
  def validate(map) when is_map(map) do
    if Enum.all?(map, fn {k, v} -> k in [:prefixItems, :unevaluatedItems] end) do
      prefix_items =
        Map.get(
          map,
          :prefixItems
        )

      unevaluated_items =
        Map.get(
          map,
          :unevaluatedItems
        )

      if is_list(prefix_items) and hd(prefix_items) == true and not unevaluated_items do
        :ok
      else
        :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end