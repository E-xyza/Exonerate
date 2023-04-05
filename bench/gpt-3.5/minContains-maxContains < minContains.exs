defmodule :"maxContains < minContains" do
  
defmodule :"minContains-maxContains < minContains" do
  def validate(object) when is_map(object), do: validate_map(object[:contains], object[:minContains], object[:maxContains])
  def validate(_), do: :error

  defp validate_map(const, min, max) do
    case const in 
      [1] -> :ok
      _ -> :error
    end |> min_max_check(min, max)
  end

  defp min_max_check(status, min, max) do
    case {status, min, max} do
      {:ok, nil, nil} -> :ok
      {:ok, min, max} when max >= min -> :ok
      _ -> :error
    end
  end
end

end
