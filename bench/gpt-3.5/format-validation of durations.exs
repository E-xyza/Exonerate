defmodule :"validation of durations-gpt-3.5" do
  def validate(duration)
      when is_binary(duration) and Regex.match?(~r{^-?P(?=[DTHM])}o, duration) do
    :ok
  end

  def validate(_) do
    :error
  end
end