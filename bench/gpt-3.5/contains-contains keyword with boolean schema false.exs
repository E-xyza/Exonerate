defmodule :"contains keyword with boolean schema false-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(list) when is_list(list) do
    if Enum.any?(list, fn element -> is_map(element) and not Map.get(element, false) end) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end