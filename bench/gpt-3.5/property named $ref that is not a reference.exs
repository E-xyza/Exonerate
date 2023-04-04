defmodule :"property named $ref that is not a reference-gpt-3.5" do
  def validate(%{"$ref" => _} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
