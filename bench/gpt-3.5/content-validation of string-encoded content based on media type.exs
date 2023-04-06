defmodule :"content-validation of string-encoded content based on media type-gpt-3.5" do
  def validate(%{"type" => "object"} = _object) do
    :ok
  end

  def validate(_) do
    :error
  end
end