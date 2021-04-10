defmodule Exonerate.Type do

 @type json ::
   %{optional(String.t) => json}
   | list(json)
   | String.t
   | number
   | boolean
   | nil

  @type t :: :string | :integer | :number | :object | :array | :boolean | :null

  @spec of(json) :: t
  def of(value) when is_binary(value), do: :string
  def of(value) when is_integer(value), do: :integer
  def of(value) when is_float(value), do: :number
  def of(value) when is_map(value), do: :object
  def of(value) when is_list(value), do: :array
  def of(value) when is_boolean(value), do: :boolean
  def of(value) when is_nil(value), do: :null

end
