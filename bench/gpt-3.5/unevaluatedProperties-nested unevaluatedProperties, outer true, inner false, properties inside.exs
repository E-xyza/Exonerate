defmodule :"nested unevaluatedProperties, outer true, inner false, properties inside-gpt-3.5" do
  def validate(%{"foo" => _} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end