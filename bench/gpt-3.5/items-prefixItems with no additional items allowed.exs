defmodule :"prefixItems with no additional items allowed-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate(object, %{})
  end

  def validate(object, _acc) when is_map(object) do
    validate(prefix_items(object), %{})
  end

  def validate(object, _acc) when is_list(object) do
    case object do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_, _) do
    :error
  end

  defp prefix_items(map) do
    if map[:items] == false do
      Enum.reduce(map[:prefixItems], %{}, fn item, acc ->
        if is_map(item) do
          Map.merge(acc, item, fn _, _, _ -> :error end)
        else
          :error
        end
      end)
    else
      :error
    end
  end
end