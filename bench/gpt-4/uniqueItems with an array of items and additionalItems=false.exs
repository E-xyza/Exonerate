defmodule :"uniqueItems with an array of items and additionalItems=false" do
  def validate(list) when is_list(list) do
    case {length(list), Enum.uniq(list)} do
      {len, unique_list} when len == length(unique_list) and len == 2 ->
        case list do
          [first, second] when is_boolean(first) and is_boolean(second) ->
            :ok
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  def validate(_), do: :error
end
