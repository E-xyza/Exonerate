defmodule :"validation of e-mail addresses" do
  def validate(email) when is_binary(email) and email =~ ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$/ do
    :ok
  end

  def validate(_), do: :error
end
