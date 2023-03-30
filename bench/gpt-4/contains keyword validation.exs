defmodule :"contains keyword validation" do
  def validate(object) when is_list(object) do
    if Enum.count(object) >= 5 do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
