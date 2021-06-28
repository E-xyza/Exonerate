defmodule Exonerate.Type do

 @type json ::
   %{optional(String.t) => json}
   | list(json)
   | String.t
   | number
   | boolean
   | nil

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
end
