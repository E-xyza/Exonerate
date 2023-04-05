defmodule :"unevaluatedItems as schema-gpt-3.5" do
  def validate(value) when is_list(value) do
    case Enum.all?(value, &is_binary/1) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end