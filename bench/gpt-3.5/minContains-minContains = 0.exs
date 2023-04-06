defmodule :"minContains-minContains = 0-gpt-3.5" do
  def validate(object) when is_map(object) do
    contains = object |> Map.values() |> Enum.count(&(&1 == 1))

    if contains >= 0 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end