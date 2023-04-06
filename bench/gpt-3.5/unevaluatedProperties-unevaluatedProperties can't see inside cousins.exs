defmodule :"unevaluatedProperties-unevaluatedProperties can't see inside cousins-gpt-3.5" do
  def validate(%{"foo" => _} = object) do
    case Map.has_key?(object, "foo") do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end