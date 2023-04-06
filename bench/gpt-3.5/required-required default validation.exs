defmodule :"required-required default validation-gpt-3.5" do
  def validate(%{"properties" => %{"foo" => _}} = object) do
    :ok
  end

  def validate(_) do
    :error
  end
end