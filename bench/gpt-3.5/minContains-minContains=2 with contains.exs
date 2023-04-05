defmodule :"minContains=2 with contains-gpt-3.5" do
  def validate(value) when is_map(value) do
    :ok
  end

  def validate(value) when is_list(value) do
    min_contains = 2
    const = 1
    found_count = Enum.count(value, &(&1 === const))

    if found_count >= min_contains do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
