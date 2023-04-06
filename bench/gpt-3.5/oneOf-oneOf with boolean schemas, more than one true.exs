defmodule :"oneOf-oneOf with boolean schemas, more than one true-gpt-3.5" do
  def validate(value) when value in [true, false] do
    :ok
  end

  def validate(value) when is_list(value) do
    process_list(value)
  end

  def validate(_) do
    :error
  end

  defp process_list([]) do
    :error
  end

  defp process_list([head | tail]) do
    case validate(head) do
      :ok ->
        if Enum.any?(tail, &(validate(&1) == :ok)) do
          :error
        else
          :ok
        end

      :error ->
        process_list(tail)
    end
  end
end