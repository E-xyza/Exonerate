defmodule :"invalid instance should not raise error when float division = inf-gpt-3.5" do
  def validate(value) do
    validate_type(value) |> validate_multiple_of()
  end

  defp validate_type(value) when is_integer(value) do
    :ok
  end

  defp validate_type(value) when is_float(value) do
    :error
  end

  defp validate_type(_) do
    :error
  end

  defp validate_multiple_of(:error) do
    :error
  end

  defp validate_multiple_of(:ok) do
    :ok
  end

  defp validate_multiple_of({:number, value}) when rem(value, 0.123456789) == 0 do
    :ok
  end

  defp validate_multiple_of(_) do
    :error
  end
end