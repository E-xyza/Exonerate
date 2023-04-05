defmodule :"non-interference across combined schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    if exclusive_maximum?(object, 0) do
      if minimum?(object, -10) do
        :ok
      else
        if multiple_of?(object, 2) do
          :ok
        else
          :error
        end
      end
    else
      :ok
    end
  end

  def validate(_) do
    :error
  end

  defp exclusive_maximum?(object, limit) do
    case Keyword.fetch(object, "exclusiveMaximum") do
      {:ok, value} -> value <= limit
      :error -> true
    end
  end

  defp minimum?(object, min) do
    case Keyword.fetch(object, "minimum") do
      {:ok, value} -> value >= min
      :error -> true
    end
  end

  defp multiple_of?(object, factor) do
    case Keyword.fetch(object, "multipleOf") do
      {:ok, value} -> rem(value, factor) == 0
      :error -> true
    end
  end
end