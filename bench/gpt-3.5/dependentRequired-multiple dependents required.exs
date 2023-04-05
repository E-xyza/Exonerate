defmodule :"multiple dependents required-gpt-3.5" do
  @doc "Validates the given JSON value.\n\nReturns :ok if the value is valid according to the schema, and :error otherwise.\n"
  def validate(json) when is_map(json) do
    quux =
      Map.get(
        json,
        "quux"
      )

    case quux do
      nil ->
        :ok

      _ ->
        case is_subset_of?(quux, ["foo", "bar"]) do
          true -> :ok
          false -> :error
        end
    end
  end

  def validate(_) do
    :error
  end

  @doc "Checks if the given list is a subset of the reference list.\n\nReturns true if all elements in the given list are also in the reference list, or if the given\nlist is empty. Returns false otherwise.\n"
  defp is_subset_of?([], _) do
    true
  end

  defp is_subset_of?([h | t], reference) do
    case Enum.member?(reference, h) do
      true -> is_subset_of?(t, reference)
      false -> false
    end
  end
end