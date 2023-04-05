defmodule :"unevaluatedProperties can't see inside cousins-gpt-3.5" do
  def validate(%{"foo" => _} = object) do
    :ok
  end

  def validate(_) do
    :error
  end
end