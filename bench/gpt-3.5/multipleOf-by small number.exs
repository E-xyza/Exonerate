defmodule :"by small number-gpt-3.5" do
  def validate(%{} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(value) when is_float(value) and rem(value, 0.0001) == 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end
