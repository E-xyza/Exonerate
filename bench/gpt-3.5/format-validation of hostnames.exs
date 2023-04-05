defmodule :"validation of hostnames-gpt-3.5" do
  def validate(%{"format" => "hostname"} = obj) do
    case is_valid_hostname?(obj) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp is_valid_hostname?(%{
         "$schema" => _,
         "type" => "string",
         "pattern" => ~r/^(?=.{1,254}$)(?:(?!-|\.)[A-Za-z0-9\-]{1,63}(?<!-)\.?)+$/
       }) do
    true
  end

  defp is_valid_hostname?(_) do
    false
  end
end