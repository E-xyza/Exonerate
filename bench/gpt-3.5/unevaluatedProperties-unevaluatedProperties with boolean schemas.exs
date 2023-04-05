defmodule :"unevaluatedProperties with boolean schemas-gpt-3.5" do
  def validate(%{"foo" => _} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end