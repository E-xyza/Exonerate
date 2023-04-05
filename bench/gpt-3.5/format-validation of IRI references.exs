defmodule :"format-validation of IRI references-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"format" => "iri-reference"} = object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
