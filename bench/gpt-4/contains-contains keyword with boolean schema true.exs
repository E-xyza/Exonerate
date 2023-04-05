defmodule :"contains keyword with boolean schema true" do
  def validate(object) when is_list(object) do
    if Enum.empty?(object) do
      :error
    else
      :ok
    end
  end
  def validate(_), do: :error
end
