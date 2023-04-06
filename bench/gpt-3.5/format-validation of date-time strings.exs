defmodule :"format-validation of date-time strings-gpt-3.5" do
  def validate(object)
      when is_binary(object) and
             Regex.match?(~r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(.\d{3})?Z/, object) do
    :ok
  end

  def validate(_) do
    :error
  end
end