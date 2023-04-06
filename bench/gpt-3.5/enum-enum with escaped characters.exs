defmodule :"enum-enum with escaped characters-gpt-3.5" do
  def validate(value) do
    case value do
      "foo\nbar" -> :ok
      "foo\rbar" -> :ok
      _ -> :error
    end
  end
end