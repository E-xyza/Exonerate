defmodule Exonerate.Type do
  @moduledoc false

  @type json ::
          %{optional(String.t()) => json}
          | list(json)
          | String.t()
          | number
          | boolean
          | nil

  @map Map.new(
         ~w(string integer number object array boolean null),
         &{&1, String.to_atom("Elixir.Exonerate.Type." <> String.capitalize(&1))}
       )

  alias Exonerate.Type.{Array, Boolean, Null, Integer, Number, Object, String}
  alias Exonerate.Context

  @type t :: String | Integer | Number | Object | Array | Boolean | Null
  @type filter :: %{__struct__: t}

  # a JsonSchema must be either true, false, or a json map.
  @type schema :: boolean | %{optional(String.t()) => json}

  @callback __struct__() :: filter
  @callback parse(Context.t(), json) :: filter
  @callback compile(filter) :: Macro.t()

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

  @spec all() :: %{optional(Type.t()) => nil}
  def all, do: Map.new([String, Integer, Number, Object, Array, Boolean, Null], &{&1, nil})

  @spec from_string(String.t()) :: t
  def from_string(string), do: Map.fetch!(@map, string)

  def intersection(map1, map2) do
    for {k, v} when is_map_key(map2, k) <- map1, into: %{} do
      # TODO: revisit this!
      if v || map2[k], do: raise("both maps should be nil")
      {k, nil}
    end
  end

  def name(string) when is_binary(string), do: "string"
  def name(integer) when is_integer(integer), do: "integer"
  def name(float) when is_float(float), do: "float"
  def name(object) when is_map(object), do: "object"
  def name(array) when is_list(array), do: "array"
  def name(boolean) when is_boolean(boolean), do: "boolean"
  def name(null) when is_nil(null), do: "null"

  def of(array) when is_list(array), do: Array
  def of(boolean) when is_boolean(boolean), do: Boolean
  def of(integer) when is_integer(integer), do: Integer
  def of(null) when is_nil(null), do: Null
  def of(float) when is_float(float), do: Number
  def of(object) when is_map(object), do: Object
  def of(string) when is_binary(string), do: String
end
