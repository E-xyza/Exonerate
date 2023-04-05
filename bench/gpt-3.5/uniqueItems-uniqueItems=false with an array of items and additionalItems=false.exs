defmodule :"uniqueItems=false with an array of items and additionalItems=false-gpt-3.5" do
  def validate(value) when is_map(value) do
    {:ok, items} = Map.fetch(value, "items", :error)
    {:ok, prefix_items} = Map.fetch(value, "prefixItems", :error)
    {:ok, unique_items} = Map.fetch(value, "uniqueItems", :error)

    case {items, prefix_items, unique_items} do
      {false, prefix, false} ->
        prefix_validators = Enum.map(prefix, &parse_type_validator/1)
        unique_prefix_items_validator = build_unique_prefix_items_validator(prefix_validators)
        &((validate_prefix_items / 1) |> validate_prefix_or_items(unique_prefix_items_validator))

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp parse_type_validator(%{"type" => type}) do
    case type do
      "boolean" -> &is_boolean/1
      _ -> %{}
    end
  end

  defp build_unique_prefix_items_validator(validators) do
    fn items ->
      grouped_items = Enum.group_by(items, &[Enum.slice(&1, 0, length(validators))])
      counts = Enum.map(grouped_items, fn {_prefix, items} -> length(items) end)
      Enum.all?(counts, &(&1 == 1))
    end
  end

  defp validate_prefix_items(validator) do
    fn value ->
      {_, items} = Map.split(value, length(validators))
      prefix_items = Map.take(value, length(validators))
      prefix_valid = validator.(prefix_items)

      if prefix_valid do
        validate_items(validators, items)
      else
        :error
      end
    end
  end

  defp validate_items(validators, items) do
    fn value ->
      if length(items) == 0 do
        :ok
      else
        do_validate_items(validators, items, value)
      end
    end
  end

  defp do_validate_items(validators, items, value) do
    item_validators =
      validators ++ repeat(&parse_type_validator/1, length(items) - length(validators))

    (Enum.zip(items, item_validators) |> Enum.all?(&apply_validator/1) and :ok) or :error
  end

  defp apply_validator({item, validator}) do
    validator.(item)
  end

  defp repeat(f, times) do
    Enum.map(1..times, &f/0)
  end
end