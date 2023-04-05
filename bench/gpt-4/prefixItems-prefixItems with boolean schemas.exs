defmodule :"prefixItems with boolean schemas" do
  def validate(list) when is_list(list) and length(list) >= 2 do
    [first | tail] = list
    [second | _] = tail

    case {first, second} do
      {true, false} -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
