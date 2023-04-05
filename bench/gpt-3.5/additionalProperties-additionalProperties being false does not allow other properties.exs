defmodule :"additionalProperties being false does not allow other properties-gpt-3.5" do
  def validate(map) when is_map(map) do
    regex = regexize("^v")

    case Map.has_key?(:bar, map) and Map.has_key?(:foo, map) and not Map.keys(map) -- [:bar, :foo] and
           Enum.all?(map, fn {k, _} -> not regex =~ to_string(k) end) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp regexize(str) do
    ~r/#{:binary.copy(str)}/
  end
end