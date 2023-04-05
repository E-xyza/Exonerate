defmodule :"enum with escaped characters-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(["foo\nbar" | rest]) do
    case validate(rest) == :ok do
      true -> :ok
      false -> :error
    end
  end

  def validate(["foo\rbar" | rest]) do
    case validate(rest) == :ok do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
