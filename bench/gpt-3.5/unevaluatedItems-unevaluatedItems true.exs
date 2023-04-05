defmodule :"unevaluatedItems true-gpt-3.5" do
  def validate(array) when is_list(array) do
    if Enum.all?(array, fn x -> is_atom(x) end) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end