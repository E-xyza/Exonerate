defmodule :"unevaluatedItems as schema" do
  def validate(list) when is_list(list) do
    case Enum.all?(list, &is_binary/1) do
      true -> :ok
      false -> :error
    end
  end
  def validate(_), do: :error
end
