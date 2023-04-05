defmodule :"not-gpt-3.5" do
  def validate(object) when is_map(object) and is_not_integer(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_not_integer(object) do
    not is_integer(object)
  end
end