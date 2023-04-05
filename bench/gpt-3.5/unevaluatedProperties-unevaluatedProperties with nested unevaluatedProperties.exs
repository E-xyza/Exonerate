defmodule :"unevaluatedProperties with nested unevaluatedProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.keys(object) |> Enum.all?(fn k -> is_binary(k) end) do
      if Map.keys(object) |> Enum.all?(fn k -> String.length(k) <= 2 end) do
        :ok
      else
        :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end