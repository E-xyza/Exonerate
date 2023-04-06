defmodule :"format-validation of durations-gpt-3.5" do
  def validate(value) when is_binary(value) do
    case Regex.match?(~r/^\d+:\d{2}:\d{2}\.\d{6}$/, value) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end