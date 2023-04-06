defmodule :"prefixItems-additional items are allowed by default-gpt-3.5" do
  def validate(object) when is_map(object) and Enum.all?(Map.values(object), &is_integer/1) do
    :ok
  end

  def validate(_) do
    :error
  end
end