defmodule :"maxContains-maxContains with contains" do
  def validate(list) when is_list(list) do
    count = Enum.count(list, fn item -> item == 1 end)

    if count <= 1, do: :ok, else: :error
  end

  def validate(_), do: :error
end
