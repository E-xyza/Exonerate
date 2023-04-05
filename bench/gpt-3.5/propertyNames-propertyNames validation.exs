defmodule :"propertyNames validation-gpt-3.5" do
  def validate(object)
      when is_map(object) and Map.keys(object) |> Enum.all?(&(String.length(&1) <= 3)) do
    :ok
  end

  def validate(_) do
    :error
  end
end