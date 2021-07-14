defmodule Exonerate.Filter.Ref do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :ref]

  alias Exonerate.Pointer
  alias Exonerate.Registry
  alias Exonerate.Validator

  @impl true
  def parse(validator = %Validator{}, %{"$ref" => ref}) do

    module = %__MODULE__{context: validator, ref: ref}

    %{validator |
      children: [module | validator.children],
      combining: [module | validator.combining]}
  end

  def combining(filter, value_ast, path_ast) do
    # obtain the function call from registry.
    uri = case filter.ref do
      "#" -> "/"
      "#" <> rest -> rest
    end

    fun = Registry.request(filter.context.schema, Pointer.from_uri(uri))

    quote do
      unquote(fun)(unquote(value_ast), unquote(path_ast))
    end
  end

  def compile(%__MODULE__{}), do: []
end
