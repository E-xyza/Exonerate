defmodule :"not-not-gpt-3.5" do
  def validate(value) do
    if not_integer?(value) do
      :ok
    else
      :error
    end
  end

  defp not_integer?(value) do
    not is_integer(value)
  end
end