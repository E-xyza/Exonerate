defmodule :"unevaluatedItems with nested tuple-gpt-3.5" do
  def validate(value) when is_list(value) do
    if Enum.reduce(value, {true, :ok}, fn item, {valid, _} ->
         case validate_item(item) do
           :error -> {false, :error}
           _ -> {valid, :ok}
         end
       end) == {true, :ok} do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_item(value) when is_binary(value) do
    :ok
  end

  defp validate_item(value) when is_number(value) do
    :ok
  end

  defp validate_item(value) when is_list(value) do
    items = Enum.reverse(value) |> Enum.drop(1) |> Enum.reverse()
    prefix_items = Enum.reverse(value) |> Enum.take(1)

    case Enum.reduce(items, {true, :ok}, fn item, {valid, _} ->
           case validate_item(item) do
             :error -> {false, :error}
             _ -> {valid, :ok}
           end
         end) do
      {_, :error} ->
        :error

      {true, _} ->
        case Enum.reduce(prefix_items, {true, :ok}, fn item, {valid, _} ->
               case validate_item(item) do
                 :error -> {false, :error}
                 _ -> {valid, :ok}
               end
             end) do
          {false, _} -> :error
          _ -> :ok
        end
    end
  end

  defp validate_item(_, _) do
    :error
  end
end