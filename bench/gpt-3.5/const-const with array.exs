defmodule :"const with array-gpt-3.5" do
  def validate(const) when is_list(const) and length(const) == 1 and is_map(Enum.at(const, 0)) do
    :ok
  end

  def validate(_) do
    :error
  end
end