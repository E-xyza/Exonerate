defmodule :"ref-$ref to boolean schema true-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(nil) do
    :error
  end

  def validate(_) do
    :error
  end
end