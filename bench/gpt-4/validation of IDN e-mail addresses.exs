defmodule :"validation of IDN e-mail addresses" do
  require Record
  import :idna

  def validate(email) when is_binary(email) do
    case to_ascii(email) do
      {:ok, ascii_email} ->
        if ascii_email =~ ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$/ do
          :ok
        else
          :error
        end

      :error ->
        :error
    end
  end

  def validate(_), do: :error
end
