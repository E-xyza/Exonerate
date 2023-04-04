defmodule :"unevaluatedProperties false" do
  def validate(object) when is_map(object) do
    if Enum.empty?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
