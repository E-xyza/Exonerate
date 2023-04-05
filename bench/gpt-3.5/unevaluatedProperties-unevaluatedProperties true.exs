defmodule :"unevaluatedProperties-unevaluatedProperties true-gpt-3.5" do
  @spec validate(term) :: atom
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
