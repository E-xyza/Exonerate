defmodule :"additional items are allowed by default" do
  def validate(list) when is_list(list) and length(list) >= 1 do
    [first | _] = list

    case first do
      value when is_integer(value) -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
