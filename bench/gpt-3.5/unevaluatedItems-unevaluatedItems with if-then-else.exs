defmodule :"unevaluatedItems with if/then/else" do
  
defmodule :"unevaluatedItems-unevaluatedItems_with_if_then_else" do
  def validate(object)
      when is_tuple(object) and tuple_size(object) == 2 and
           element(1, object) == :ok and is_map(element(2, object)) 
      do
    schema = %{
      "else" => %{
        "prefixItems" => [true, true, true, %{"const" => "else"}]
      },
      "if" => %{
        "prefixItems" => [true, %{"const" => "bar"}]
      },
      "prefixItems" => [%{"const" => "foo"}],
      "then" => %{
        "prefixItems" => [true, true, %{"const" => "then"}]
      },
      "type" => "array",
      "unevaluatedItems" => false
    }

    case validate_schema(schema, object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_), do: :error

  defp validate_schema(%{"type" => "array", "prefixItems" => prefix_items,
                         "if" => if_value, "then" => then_value, "else" => else_value,
                         "unevaluatedItems" => unevaluated_items}, array) do
    if unevaluated_items do
      cond do
        validate_condition(if_value, array) -> validate_branch(then_value, array)
        true -> validate_branch(else_value, array)
      end
    else
      case length(array) do
        length when length < length(prefix_items) -> false
        length when length == length(prefix_items) -> validate_items(array, prefix_items)
        _ -> case Enum.split(array, length(prefix_items)) do
          {prefix, rest} -> validate_items(prefix, prefix_items) and
                             validate_branch(else_value, rest, if_value, then_value)
          _ -> false
        end
      end
    end
  end

  defp validate_schema(_schema, _object), do: false

  defp validate_items([], []), do: true
  defp validate_items([head | tail], [%{"const" => const} | rest]),
    do: head == const and validate_items(tail, rest)
  defp validate_items([_ | _], [%{"const" => _} | _rest]), do: false
  defp validate_items([_ | _], []), do: false

  defp validate_branch(nil, []) -> true
  defp validate_branch(schema, array) -> validate_schema(schema, array)
  defp validate_branch(schema, array, if_value, then_value) do
    if validate_condition(if_value, array) do
      validate_schema(then_value, array)
    else
      validate_schema(schema, array)
    end
  end

  defp validate_condition(nil, _), do: true
  defp validate_condition(schema, array) do
    case validate_schema(schema, array) do
      true -> true
      false -> false
    end
  end
end

end
