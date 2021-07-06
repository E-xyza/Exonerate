defmodule Exonerate.Type do
 @type json ::
   %{optional(String.t) => json}
   | list(json)
   | String.t
   | number
   | boolean
   | nil

  # a JsonSchema must be either true, false, or a json map.
  @type schema :: boolean | %{optional(String.t) => json}

  @type t :: :string | :integer | :number | :object | :array | :boolean | :null

  @guards %{
    string: :is_binary,
    integer: :is_integer,
    number: :is_number,
    object: :is_map,
    array: :is_list,
    boolean: :is_boolean,
    null: :is_nil
  }

  def guard(type), do: Map.fetch!(@guards, type)

  defguard is_schema(schema) when is_map(schema) or is_boolean(schema)

  def of(string) when is_binary(string), do: "string"
  def of(integer) when is_integer(integer), do: "integer"
  def of(float) when is_float(float), do: "float"
  def of(object) when is_map(object), do: "object"
  def of(array) when is_list(array), do: "array"
  def of(boolean) when is_boolean(boolean), do: "boolean"
  def of(null) when is_nil(null), do: "null"
end
