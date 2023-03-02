defmodule Exonerate.Combining.If do
  @moduledoc false
  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    # note we have to pull the parent pointer because we need to see "if"/"then"/"else"
    # clauses.

    parent_pointer = JsonPointer.backtrack!(pointer)

    opts =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(parent_pointer)
      |> case do
        %{"unevaluatedProperties" => _} -> Keyword.put(opts, :track_properties, true)
        _ -> opts
      end

    tracked = opts[:track_properties]

    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(parent_pointer)
    |> build_code(name, pointer, parent_pointer, tracked, opts)
    |> Tools.maybe_dump(opts)
  end

  def build_code(subschema, name, pointer, parent_pointer, tracked, opts) do
    ok =
      if tracked do
        quote do
          {:ok, MapSet.new()}
        end
      else
        :ok
      end

    {then_clause, then_context} =
      if Map.get(subschema, "then") do
        then_pointer = JsonPointer.join(parent_pointer, "then")

        {quote do
           unquote(then_call(name, parent_pointer, tracked))(content, path)
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
        {ok, []}
      end

    {else_clause, else_context} =
      if Map.get(subschema, "else") do
        else_pointer = JsonPointer.join(parent_pointer, "else")

        {quote do
           unquote(else_call(name, parent_pointer, tracked))(content, path)
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
        {ok, []}
      end

    entrypoint_call = entrypoint_call(name, pointer, tracked)

    subschema
    |> Map.fetch!("if")
    |> Tools.degeneracy()
    |> case do
      :ok ->
        quote do
          @compile {:inline, [{unquote(entrypoint_call), 2}]}
          defp unquote(entrypoint_call)(content, path) do
            unquote(then_clause)
          end

          unquote(then_context)
        end

      :error ->
        quote do
          @compile {:inline, [{unquote(entrypoint_call), 2}]}
          defp unquote(entrypoint_call)(content, path) do
            unquote(else_clause)
          end

          unquote(else_context)
        end

      :unknown ->
        standard_if(
          entrypoint_call,
          then_clause,
          then_context,
          else_clause,
          else_context,
          name,
          pointer,
          tracked,
          opts
        )
    end
  end

  defp standard_if(
         entrypoint_call,
         then_clause,
         then_context,
         else_clause,
         else_context,
         name,
         pointer,
         true,
         opts
       ) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        case unquote(if_call(name, pointer, true))(content, path) do
          {:ok, seen} ->
            case unquote(then_clause) do
              {:ok, new_seen} ->
                {:ok, MapSet.union(seen, new_seen)}

              error = {:error, _} ->
                error
            end

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

  defp standard_if(
         entrypoint_call,
         then_clause,
         then_context,
         else_clause,
         else_context,
         name,
         pointer,
         tracked,
         opts
       ) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        case unquote(if_call(name, pointer, tracked))(content, path) do
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

  defp if_call(name, pointer, tracked) do
    pointer
    |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
    |> Tools.pointer_to_fun_name(authority: name)
  end

  defp nexthop(name, pointer, next, tracked) do
    pointer
    |> JsonPointer.join(next)
    |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
    |> Tools.pointer_to_fun_name(authority: name)
  end

  defp entrypoint_call(name, pointer, tracked), do: nexthop(name, pointer, ":entrypoint", tracked)

  defp then_call(name, pointer, tracked), do: nexthop(name, pointer, "then", tracked)

  defp else_call(name, pointer, tracked), do: nexthop(name, pointer, "else", tracked)
end
