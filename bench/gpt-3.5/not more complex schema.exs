defmodule :"not more complex schema-gpt-3.5" do
  def validate(object) when is_map(object) and not Map.has_key?(object, :foo) do
    :ok
  end

  def validate(_) do
    :error
  end
end
