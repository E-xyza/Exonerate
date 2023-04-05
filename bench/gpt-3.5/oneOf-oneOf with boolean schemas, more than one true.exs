defmodule :"oneOf with boolean schemas, more than one true-gpt-3.5" do
  def validate(true) do
    :ok
  end

  def validate(%{"oneOf" => [true, _, _]}) do
    :error
  end

  def validate(%{"oneOf" => [_, true, _]}) do
    :error
  end

  def validate(%{"oneOf" => [_, _, true]}) do
    :error
  end

  def validate(_) do
    :error
  end
end