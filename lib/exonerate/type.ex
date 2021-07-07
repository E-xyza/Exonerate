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

  @map Map.new(
    ~w(string integer number object array boolean null),
    &{&1, String.to_atom("Elixir.Exonerate.Type." <> String.capitalize(&1))})

  @callback compile(Validator.t) :: Macro.t

  alias Exonerate.Type.{Array, Boolean, Null, Integer, Number, Object, String}

  @type t :: String | Integer | Number | Object | Array | Boolean | Null

  @guards %{
    String => :is_binary,
    Integer => :is_integer,
    Number => :is_number,
    Object => :is_map,
    Array => :is_list,
    Boolean => :is_boolean,
    Null => :is_nil
  }

  @spec guard(t) :: atom
  def guard(type), do: Map.fetch!(@guards, type)

  defguard is_schema(schema) when is_map(schema) or is_boolean(schema)

  @spec all() :: [t]
  def all, do: [String, Integer, Number, Object, Array, Boolean, Null]

  @spec from_string(String.t) :: t
  def from_string(string), do: Map.fetch!(@map, string)

  def of(string) when is_binary(string), do: "string"
  def of(integer) when is_integer(integer), do: "integer"
  def of(float) when is_float(float), do: "float"
  def of(object) when is_map(object), do: "object"
  def of(array) when is_list(array), do: "array"
  def of(boolean) when is_boolean(boolean), do: "boolean"
  def of(null) when is_nil(null), do: "null"
end
