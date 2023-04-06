defmodule :"unevaluatedItems-unevaluatedItems can't see inside cousins-gpt-3.5" do
  def validate(%{allOf: all_of}) do
    process_all_of(all_of)
  end

  def validate(_) do
    :error
  end

  defp process_all_of(all_of) do
    prefix_items = get_prefix_items(all_of)
    is_valid_prefix_items = Enum.all?(prefix_items, fn item -> item == true end)

    if is_valid_prefix_items do
      unevaluated_items = get_unevaluated_items(all_of)

      if unevaluated_items == false do
        :ok
      else
        :error
      end
    else
      :error
    end
  end

  defp get_prefix_items(all_of) do
    all_of |> Enum.map(& &1.prefixItems) |> List.flatten()
  end

  defp get_unevaluated_items(all_of) do
    all_of |> Enum.map(& &1.unevaluatedItems) |> List.first()
  end
end