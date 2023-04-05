defmodule :"contains keyword with const keyword" do
  def validate(object) when is_list(object) do
    if Enum.any?(object, &(&1 === 5)) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
