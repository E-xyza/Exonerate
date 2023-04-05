defmodule :"maximum-maximum validation-gpt-3.5" do
  def validate(json) when is_map(json) do
    if json_has_valid_maximum?(json) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp json_has_valid_maximum?(json) do
    case Map.fetch(json, "maximum") do
      {:ok, max} when is_float(max) and max <= 3.0 -> true
      _ -> false
    end
  end
end
