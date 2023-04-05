defmodule :"unevaluatedItems with not-gpt-3.5" do
  def validate(array) when is_list(array) do
    prefix_items =
      case Enum.split_while(array, &(&1 == "foo")) do
        {prefix_items, ["foo" | rest]} -> prefix_items
        _ -> []
      end

    not_prefix_items =
      case Enum.split_while(array, &(&1 in [true, "bar"])) do
        {not_prefix_items, [true | ["bar" | rest]]} -> not_prefix_items
        _ -> []
      end

    is_valid = length(prefix_items) > 0 and length(not_prefix_items) == 0

    if is_valid do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end