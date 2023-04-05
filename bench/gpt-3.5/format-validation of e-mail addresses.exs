defmodule :"format-validation of e-mail addresses-gpt-3.5" do
  @moduledoc "This module provides a `validate/1` function to validate JSON data against a specified JSON schema\n"
  @specs validate(map) :: :ok | :error
  def validate(data) when is_map(data) do
    case validate_email_field(data["email"]) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_email_field(email)
       when is_binary(email) and
              String.match?(email, ~r/^[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+$/i) do
    :ok
  end

  defp validate_email_field(_) do
    {:error, "Invalid email format"}
  end
end
