defmodule :"prefixItems-a schema given for prefixItems" do
  def validate(list) when is_list(list) and length(list) >= 2 do
    [first | tail] = list
    [second | _] = tail

    case {is_integer(first), is_binary(second)} do
      {true, true} -> :ok
      _ -> :error
    end
  end

  def validate(_), do: :error
end
