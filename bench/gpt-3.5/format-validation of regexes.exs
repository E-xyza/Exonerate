defmodule :"format-validation of regexes-gpt-3.5" do
  def validate(object) when is_binary(object) and Regex.regex?(~r/#{object}/) do
    :ok
  end

  def validate(_) do
    :error
  end
end