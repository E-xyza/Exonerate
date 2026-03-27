defmodule Exonerate.Combining do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Modules
  alias Exonerate.Tools
  alias Exonerate.Type.Array

  # Note: This module exposes the "standard" combining filters (excluding dependentSchemas).
  # For the full combining modules map including dependentSchemas, use Exonerate.Modules.

  @doc "Returns the standard combining filter modules map (excludes dependentSchemas)."
  def modules do
    # Return standard combining modules without dependentSchemas
    Modules.combining_filters()
    |> Map.new(&{&1, Modules.combining(&1)})
  end

  @doc "Returns the standard combining filter names."
  defdelegate filters(), to: Modules, as: :combining_filters

  @doc "Returns true if the filter is a combining filter."
  defdelegate filter?(filter), to: Modules, as: :combining?

  @doc "Merges the combining modules into the given map."
  def merge(map), do: Map.merge(map, modules())

  # TODO: refactor this.
  def adjust("not"), do: ["not", ":entrypoint"]
  def adjust("if"), do: ["if", ":entrypoint"]
  def adjust(other), do: [other]

  defmacro initializer(first_unseen_index_var_ast, resource, pointer, opts) do
    context = Tools.subschema(__CALLER__, resource, pointer)

    List.wrap(
      if Array.needs_seen_tracking?(context, opts),
        do:
          (quote do
             unquote(first_unseen_index_var_ast) = 0
           end)
    )
  end

  def dedupe(macro, caller, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    dedupe(macro, caller.module, call)
  end

  def dedupe(macro, caller, resource, pointer, extension, opts) do
    call = Tools.call(resource, pointer, extension, opts)
    dedupe(macro, caller.module, call)
  end

  defp dedupe(macro, module, call) do
    if Cache.register_context(module, call) do
      macro
    else
      []
    end
  end
end
