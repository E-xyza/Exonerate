defmodule :"validation of relative JSON pointers-gpt-3.5" do
  def validate(%{"format" => "relative-json-pointer"}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
