defmodule :"minContains = 0" do
  def validate(json) when is_list(json) do
    if Enum.count(json, &(&1 == 1)) >= 0, do: :ok, else: :error
  end

  def validate(_), do: :error
end
