defmodule :"minContains-maxContains < minContains-gpt-3.5" do
  def validate(object) when is_map(object) do
    :error
  end

  def validate([]) do
    :error
  end

  def validate(list) when is_list(list) do
    if Enum.count(list, &(&1 == 1)) >= 1 and Enum.count(list, fn _ -> true end) >= 3 do
      :ok
    else
      :error
    end
  end
end