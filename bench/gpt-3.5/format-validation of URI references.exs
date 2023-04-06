defmodule :"format-validation of URI references-gpt-3.5" do
  def validate(object) when is_string(object) and String.valid?(object, :url) do
    :ok
  end

  def validate(_) do
    :error
  end
end