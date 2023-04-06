defmodule :"unevaluatedItems-unevaluatedItems with nested unevaluatedItems-gpt-3.5" do
  def validate(array) when is_list(array) do
    res =
      array
      |> Enum.map(fn item ->
        case item do
          _ when is_binary(item) -> :ok
          _ -> :error
        end
      end)

    if Enum.all?(res, &(&1 == :ok)) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end