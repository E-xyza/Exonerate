defmodule :"enum with escaped characters-gpt-3.5" do
  def validate(json) when is_map(json) do
    case Map.get(json, "enum") do
      ["foo\nbar", "foo\rbar"] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end