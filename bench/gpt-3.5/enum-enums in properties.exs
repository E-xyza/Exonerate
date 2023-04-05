defmodule :"enums in properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    {:ok, _} = Map.get_and_update(object, :bar, fn _old_val -> :not_found end)

    case Map.has_key?(object, :foo) do
      true -> {:ok, _}
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end