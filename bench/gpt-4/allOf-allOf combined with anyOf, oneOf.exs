defmodule :"allOf-allOf combined with anyOf, oneOf" do
  def validate(value) when is_number(value) do
    all_of_result = all_of_validate(value)
    any_of_result = any_of_validate(value)
    one_of_result = one_of_validate(value)

    if all_of_result == :ok and (any_of_result == :ok or one_of_result == :ok) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp all_of_validate(value), do: if(rem(value, 2) == 0, do: :ok, else: :error)
  defp any_of_validate(value), do: if(rem(value, 3) == 0, do: :ok, else: :error)
  defp one_of_validate(value), do: if(rem(value, 5) == 0, do: :ok, else: :error)
end
