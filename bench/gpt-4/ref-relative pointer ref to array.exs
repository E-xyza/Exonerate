defmodule :"ref-relative pointer ref to array" do
  def validate(list) when is_list(list) do
    case Enum.take(list, 2) do
      [first, second] ->
        cond do
          is_integer(first) and is_integer(second) ->
            :ok

          true ->
            :error
        end

      [first] ->
        cond do
          is_integer(first) ->
            :ok

          true ->
            :error
        end

      [] ->
        :ok

      _ ->
        :error
    end
  end

  def validate(_), do: :error
end
