defmodule :"required validation-gpt-3.5" do
  def validate(%{"foo" => _} = map) when is_map(map) do
    :ok
  end

  def validate(_) do
    :error
  end
end