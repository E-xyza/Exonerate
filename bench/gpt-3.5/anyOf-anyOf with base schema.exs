defmodule :"anyOf-anyOf with base schema-gpt-3.5" do
  def validate(value) when is_binary(value) do
    case String.length(value) do
      len when len <= 2 -> :ok
      len when len >= 4 -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end