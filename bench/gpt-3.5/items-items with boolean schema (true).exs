defmodule :"items-items with boolean schema (true)-gpt-3.5" do
  def validate(object) when is_list(object) do
    Enum.reduce(object, :ok, fn item, acc ->
      if is_boolean(item) do
        acc
      else
        :error
      end
    end)
  end

  def validate(_) do
    :error
  end
end