defmodule :"nested allOf, to check validation semantics-gpt-3.5" do
  def validate(null) when null == nil do
    :ok
  end

  def validate(_) do
    :error
  end

  def process_schema(schema) when is_map(schema) and schema["allOf"] do
    all_of_schemas = schema["allOf"]

    for sub_schema <- all_of_schemas do
      validate(sub_schema)
    end
  end

  def process_schema(schema) when is_map(schema) and schema["type"] == "null" do
    &validate/1
  end

  def process_schema(_) do
    &validate/1
  end
end