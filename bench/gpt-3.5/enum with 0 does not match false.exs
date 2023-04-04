defmodule :"enum with 0 does not match false-gpt-3.5" do
  def validate(enum_value) do
    case enum_value do
      %{enum: [0]} -> :ok
      _ -> :error
    end
  end
end
