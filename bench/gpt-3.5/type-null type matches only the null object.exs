defmodule :"null type matches only the null object-gpt-3.5" do
  def validate(null) when is_nil(null) do
    :ok
  end

  def validate(_) do
    :error
  end
end