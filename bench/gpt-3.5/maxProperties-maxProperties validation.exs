defmodule :"maxProperties-maxProperties validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate(object, %{"maxProperties" => 2})
  end

  def validate(_) do
    :error
  end

  defp validate(object, %{"maxProperties" => max}) when map_size(object) <= max do
    :ok
  end

  defp validate(_, _) do
    :error
  end
end
