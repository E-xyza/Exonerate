defmodule Exonerate.Type do
  @moduledoc false

  @type json ::
          %{optional(String.t()) => json}
          | list(json)
          | String.t()
          | number
          | boolean
          | nil

  @module Map.new(
            ~w(string integer number object array boolean null),
            &{&1, Module.concat(Elixir.Exonerate.Type, String.capitalize(&1))}
          )

  def module(type), do: @module[type]

  @all Map.keys(@module)
  def all, do: @all

  @spec of(json) :: String.t()
  def of(value) when is_binary(value), do: "string"
  def of(value) when is_map(value), do: "object"
  def of(value) when is_list(value), do: "array"
  def of(value) when is_integer(value), do: "integer"
  def of(value) when is_float(value), do: "number"
  def of(value) when is_boolean(value), do: "boolean"
  def of(value) when is_nil(value), do: "null"

  @macrocallback filter(resource :: String.t(), JsonPointer.t(), keyword) :: Macro.t()
  @macrocallback accessories(resource :: String.t(), JsonPointer.t(), keyword) :: Macro.t()
end
