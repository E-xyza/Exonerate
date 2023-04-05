defmodule :"validation of time strings-gpt-3.5" do
  def validate(time) when is_binary(time) and :erlang.time_parse(time) != :error do
    :ok
  end

  def validate(_) do
    :error
  end
end