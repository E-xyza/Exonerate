defmodule :"minContains-maxContains = minContains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Enum.count(object, fn _, v -> v == 1 end) do
      count when count >= 2 -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end