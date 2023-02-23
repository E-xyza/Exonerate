defmodule Exonerate.Combining.If do
  @moduledoc false
  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    # note we have to pull the parent pointer because we need to see "if"/"then"/"else"
    # clauses.

    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(parent_pointer)
    |> build_code(name, pointer, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def build_code(subschema, name, pointer, parent_pointer, opts) do
    {then_clause, then_context} =
      if Map.get(subschema, "then") do
        then_pointer = JsonPointer.traverse(parent_pointer, "then")

        {quote do
           unquote(then_call(name, parent_pointer))(content, path)
         end,
         quote do
           require Exonerate.Combining.Then

           Exonerate.Combining.Then.filter_from_cached(
             unquote(name),
             unquote(then_pointer),
             unquote(opts)
           )
         end}
      else
        {:ok, []}
      end

    {else_clause, else_context} =
      if Map.get(subschema, "else") do
        else_pointer = JsonPointer.traverse(parent_pointer, "else")

        {quote do
           unquote(else_call(name, parent_pointer))(content, path)
         end,
         quote do
           require Exonerate.Combining.Else

           Exonerate.Combining.Else.filter_from_cached(
             unquote(name),
             unquote(else_pointer),
             unquote(opts)
           )
         end}
      else
        {:ok, []}
      end

    quote do
      defp unquote(entrypoint_call(name, pointer))(content, path) do
        case unquote(if_call(name, pointer))(content, path) do
          :ok ->
            unquote(then_clause)

          {:error, _} ->
            unquote(else_clause)
        end
      end

      require Exonerate.Context
      Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))

      unquote(then_context)
      unquote(else_context)
    end
  end

  # callsite generation

  defp if_call(name, pointer) do
    Tools.pointer_to_fun_name(pointer, authority: name)
  end

  defp nexthop(name, pointer, next) do
    pointer
    |> JsonPointer.traverse(next)
    |> Tools.pointer_to_fun_name(authority: name)
  end

  defp entrypoint_call(name, pointer), do: nexthop(name, pointer, ":entrypoint")

  defp then_call(name, pointer), do: nexthop(name, pointer, "then")

  defp else_call(name, pointer), do: nexthop(name, pointer, "else")
end
