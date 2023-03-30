defmodule :"contains keyword with boolean schema false" do
  def validate(object) when is_list(object) do
    if Enum.empty?(object) do
      :ok
    else
      :error
    end
  end
  def validate(_), do: :error
end
