defmodule :"$ref to boolean schema false-gpt-3.5" do
  def validate(object) when is_boolean(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end