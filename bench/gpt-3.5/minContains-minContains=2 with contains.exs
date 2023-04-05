defmodule :"minContains=2 with contains" do
  
defmodule :"minContains-minContains=2 with contains" do
  def validate(object) when is_map(object) do
    num_matches_const = object
    |> Enum.count(fn (value) -> value === 1 end)
    num_matches_const >= 2 && Enum.count(object, fn (value) -> Map.has_key?(value, :contains) end) > 0  ? :ok : :error
  end

  def validate(_), do: :error
end

end
