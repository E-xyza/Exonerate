defmodule :"validation of URIs-gpt-3.5" do
  def validate(%{"format" => "uri"} = _json) do
    :ok
  end

  def validate(_) do
    :error
  end
end
