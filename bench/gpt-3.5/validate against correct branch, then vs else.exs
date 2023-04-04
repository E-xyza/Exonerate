defmodule :"validate against correct branch, then vs else-gpt-3.5" do
  def validate(json) when is_map(json) do
    if Map.has_key?(json, "else") and Map.has_key?(json, "if") and Map.has_key?(json, "then") do
      if exclusive_maximum(json["if"]) and multiple_of(json["else"]) and minimum(json["then"]) do
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

  defp exclusive_maximum(json) when is_map(json) and Map.has_key?(json, "exclusiveMaximum") do
    json["exclusiveMaximum"] == 0
  end

  defp exclusive_maximum(_) do
    false
  end

  defp multiple_of(json) when is_map(json) and Map.has_key?(json, "multipleOf") do
    rem(
      json["multipleOf"],
      2
    ) == 0
  end

  defp multiple_of(_) do
    false
  end

  defp minimum(json) when is_map(json) and Map.has_key?(json, "minimum") do
    json["minimum"] == -10
  end

  defp minimum(_) do
    false
  end
end
