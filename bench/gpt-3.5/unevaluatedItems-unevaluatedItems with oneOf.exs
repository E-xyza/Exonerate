defmodule :"unevaluatedItems with oneOf-gpt-3.5" do
  def validate(object) when is_list(object) do
    case object do
      [{"foo"} | items] ->
        case Enum.find_index(items, fn x -> x != "bar" and x != "baz" end) do
          nil -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end