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
  def of(json) when is_binary(json), do: "string"
  def of(json) when is_map(json), do: "object"
  def of(json) when is_list(json), do: "array"
  def of(json) when is_integer(json), do: "integer"
  def of(json) when is_float(json), do: "number"
  def of(json) when is_boolean(json), do: "boolean"
  def of(json) when is_nil(json), do: "null"

  @macrocallback filter(resource :: String.t(), JsonPtr.t(), keyword) :: Macro.t()
  @macrocallback accessories(resource :: String.t(), JsonPtr.t(), keyword) :: Macro.t()
end
