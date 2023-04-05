defmodule :"unevaluatedProperties with oneOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_object(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case validate_properties(object) do
      :ok -> :ok
      _ -> validate_one_of(object)
    end
  end

  defp validate_properties(object) do
    case Map.has_key?(object, :foo) do
      true ->
        case Map.get(object, :foo) do
          s when is_binary(s) -> :ok
          _ -> :error
        end

      false ->
        :error
    end
  end

  defp validate_one_of(object) do
    case validate_one_of_clause(object, %{bar: "bar"}) do
      :ok ->
        :ok

      _ ->
        case validate_one_of_clause(object, %{baz: "baz"}) do
          :ok -> :ok
          _ -> :error
        end
    end
  end

  defp validate_one_of_clause(object, clause) do
    case Map.has_key?(object, :foo) do
      true ->
        :error

      false ->
        case Map.has_key?(object, Keyword.keys(clause)) do
          true ->
            Enum.all?(
              Enum.map(Keyword.keys(clause), fn k -> Map.get(object, k) == Map.get(clause, k) end),
              & &1
            ) && :ok

          false ->
            :error
        end
    end
  end
end