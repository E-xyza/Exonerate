defmodule :"required-required default validation-gpt-3.5" do
  def validate(map) when is_map(map) and map["properties"] == %{"foo" => %{}} do
    :ok
  end

  def validate(_) do
    :error
  end
end
