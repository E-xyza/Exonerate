defmodule Exonerate.Combining do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Type.Array

  @modules %{
    "anyOf" => Exonerate.Combining.AnyOf,
    "allOf" => Exonerate.Combining.AllOf,
    "oneOf" => Exonerate.Combining.OneOf,
    "not" => Exonerate.Combining.Not,
    "$ref" => Exonerate.Combining.Ref,
    "if" => Exonerate.Combining.If
  }

  @filters Map.keys(@modules)

  def merge(map), do: Map.merge(map, @modules)

  def modules, do: @modules

  def filters, do: @filters

  def filter?(filter), do: is_map_key(@modules, filter)

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

    if Cache.register_context(caller.module, call) do
      macro
    else
      []
    end
  end
end
