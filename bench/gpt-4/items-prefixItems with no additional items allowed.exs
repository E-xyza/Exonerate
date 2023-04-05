defmodule :"items-prefixItems with no additional items allowed" do
  def validate(value) when is_list(value) do
    if length(value) <= 3 do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
