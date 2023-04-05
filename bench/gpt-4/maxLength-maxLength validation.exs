defmodule :"maxLength-maxLength validation" do
  def validate(string) when is_binary(string) do
    if byte_size(string) <= 2, do: :ok, else: :error
  end

  def validate(_), do: :error
end
