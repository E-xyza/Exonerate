defmodule Exonerate.Type do
  @moduledoc false

  alias Exonerate.Modules

  @type json ::
          %{optional(String.t()) => json}
          | list(json)
          | String.t()
          | number
          | boolean
          | nil

  @doc "Returns the module for a JSON type."
  defdelegate module(type), to: Modules, as: :type

  @doc "Returns all type names."
  defdelegate all(), to: Modules, as: :all_types

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
