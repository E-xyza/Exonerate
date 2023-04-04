defmodule :"validation of IRIs-gpt-3.5" do
  def validate(%{"format" => "iri"} = value) do
    :ok
  end

  def validate(_) do
    :error
  end
end
