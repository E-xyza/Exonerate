defmodule :"validation of URI references-gpt-3.5" do
  def validate(object)
      when is_binary(object) and Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9+.-]*:/, object) do
    :ok
  end

  def validate(_) do
    :error
  end
end