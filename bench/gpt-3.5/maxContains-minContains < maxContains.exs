defmodule :"maxContains-minContains < maxContains-gpt-3.5" do
  def validate(json) when is_list(json) do
    validate_list(json, 0)
  end

  defp validate_list([], _) do
    :error
  end

  defp validate_list(_, max) when max > 3 do
    :error
  end

  defp validate_list([elem | rest], max) do
    case contains(elem) do
      :ok ->
        validate_list(rest, max + 1)

      :error ->
        case max do
          0 -> validate_list(rest, 1)
          _ -> validate_list(rest, max)
        end
    end
  end

  defp contains(elem) do
    case elem do
      1 -> :ok
      _ -> :error
    end
  end
end