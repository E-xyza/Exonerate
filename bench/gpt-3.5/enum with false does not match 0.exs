defmodule :"enum with false does not match 0-gpt-3.5" do
  def validate({"enum", [false]}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
