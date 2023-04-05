defmodule :"validation of UUIDs-gpt-3.5" do
  def validate(%{format: "uuid"} = value) when is_binary(value) and String.valid?(value, :uuid) do
    :ok
  end

  def validate(_) do
    :error
  end
end