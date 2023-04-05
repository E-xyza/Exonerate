defmodule :"ref-naive replacement of $ref with its destination is not correct-gpt-3.5" do
  def validate(data) when is_map(data) or is_list(data) do
    validate(data, schema())
  end

  def schema() do
    %{
      "$defs" => %{"a_string" => %{"type" => "string"}},
      "enum" => [%{"$ref" => "#/$defs/a_string"}]
    }
  end

  def validate(data, %{"type" => "object"} = schema) when is_map(data) do
    :ok
  end

  def validate(_data, _schema) do
    :error
  end
end
