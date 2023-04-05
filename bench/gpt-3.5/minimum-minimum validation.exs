defmodule :"minimum validation-gpt-3.5" do
  def validate(%{minimum: min} = object) when is_float(min) and obj >= min do
    :ok
  end

  def validate(_) do
    :error
  end
end
