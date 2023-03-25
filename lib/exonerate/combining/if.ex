defmodule Exonerate.Combining.If do
  @moduledoc false
  alias Exonerate.Degeneracy
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # note we have to pull the parent pointer because we need to see the
    # "then"/"else" clauses.
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(resource, parent_pointer)
    |> build_filter(resource, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, parent_pointer, opts) do
    entrypoint_call = call(["if", ":entrypoint"], resource, parent_pointer, opts)
    if_expr = expr("if", resource, parent_pointer, opts)
    then_expr = then_expr(context, resource, parent_pointer, opts)
    else_expr = else_expr(context, resource, parent_pointer, opts)

    {function, context_names} =
      case {Degeneracy.class(context["if"]), opts[:tracked]} do
        {:ok, _} ->
          {build_then(entrypoint_call, then_expr), ["then"]}

        {:error, _} ->
          {build_else(entrypoint_call, else_expr), ["else"]}

        {:unknown, :object} ->
          {build_tracked(entrypoint_call, if_expr, then_expr, else_expr), ["if", "then", "else"]}

        {:unknown, :array} ->
          {build_tracked(entrypoint_call, if_expr, then_expr, else_expr), ["if", "then", "else"]}

        {:unknown, nil} ->
          {build_untracked(entrypoint_call, if_expr, then_expr, else_expr),
           ["if", "then", "else"]}
      end

    contexts =
      Enum.flat_map(
        context_names,
        &List.wrap(if is_map_key(context, &1), do: context(&1, resource, parent_pointer, opts))
      )

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  defp build_then(entrypoint_call, then_expr) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        unquote(then_expr)
      end
    end
  end

  defp build_else(entrypoint_call, else_expr) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        unquote(else_expr)
      end
    end
  end

  defp build_tracked(entrypoint_call, if_expr, then_expr, else_expr) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        require Exonerate.Tools

        case unquote(if_expr) do
          {:ok, if_seen} ->
            unquote(then_expr)

          Exonerate.Tools.error_match(_error) ->
            unquote(else_expr)
        end
      end
    end
  end

  defp build_untracked(entrypoint_call, if_expr, then_expr, else_expr) do
    quote do
      defp unquote(entrypoint_call)(content, path) do
        require Exonerate.Tools

        case unquote(if_expr) do
          :ok ->
            unquote(then_expr)

          Exonerate.Tools.error_match(error) ->
            unquote(else_expr)
        end
      end
    end
  end

  defp then_expr(context, resource, parent_pointer, opts) do
    case {context["then"], opts[:tracked]} do
      {nil, :object} ->
        quote do
          {:ok, if_seen}
        end

      {nil, _} ->
        :ok

      {_, :object} ->
        then = expr("then", resource, parent_pointer, opts)

        quote do
          require Exonerate.Tools

          case unquote(then) do
            {:ok, then_seen} ->
              {:ok, MapSet.union(if_seen, then_seen)}

            Exonerate.Tools.error_match(error) ->
              error
          end
        end

      {_, :array} ->
        then = expr("then", resource, parent_pointer, opts)

        quote do
          require Exonerate.Tools

          case unquote(then) do
            {:ok, then_seen} ->
              {:ok, max(if_seen, then_seen)}

            Exonerate.Tools.error_match(error) ->
              error
          end
        end

      _ ->
        expr("then", resource, parent_pointer, opts)
    end
  end

  defp else_expr(context, resource, parent_pointer, opts) do
    case {context["else"], opts[:tracked]} do
      {nil, :object} ->
        quote do
          {:ok, MapSet.new()}
        end

      {nil, :array} ->
        {:ok, 0}

      {nil, _} ->
        :ok

      _ ->
        expr("else", resource, parent_pointer, opts)
    end
  end

  defp expr(what, resource, parent_pointer, opts) do
    quote do
      unquote(call(what, resource, parent_pointer, opts))(content, path)
    end
  end

  defp call(what, resource, parent_pointer, opts) do
    Tools.call(resource, JsonPointer.join(parent_pointer, what), opts)
  end

  defp context(what, resource, parent_pointer, opts) do
    pointer = JsonPointer.join(parent_pointer, what)

    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
    end
  end
end
