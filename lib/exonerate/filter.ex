defmodule Exonerate.Filter do
  @moduledoc false

  alias Exonerate.Type
  alias Exonerate.Context

  # to be filled with a more comprensive list later.
  @type t :: module
  @type filter :: %{__struct__: t}

  @callback parse(Context.t() | Type.filter(), Type.json()) :: Context.t() | Type.filter()

  def from_string(filter), do: String.to_atom("Elixir.Exonerate.Filter.#{capitalize(filter)}")

  @spec parse(Context.t(), Filter.t()) :: Context.t()
  def parse(validation, module), do: parse(validation, module, Context.traverse(validation))

  @spec parse(Context.t(), Filter.t(), Type.json()) :: Context.t()
  @spec parse(Type.filter(), Filter.t(), Type.json()) :: Type.filter()
  def parse(context_or_filter, module, json), do: module.parse(context_or_filter, json)

  defp capitalize(<<?$, rest::binary>>), do: capitalize(rest)

  defp capitalize(<<first::binary-size(1), rest::binary>>) do
    String.capitalize(first) <> rest
  end
end
