defmodule Exonerate.Combining.If do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    # note we have to pull the parent pointer because we need to see the
    # "then"/"else" clauses.
    parent_pointer = JsonPointer.backtrack!(pointer)

    __CALLER__
    |> Tools.subschema(authority, parent_pointer)
    |> build_filter(authority, parent_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, parent_pointer, opts) do
    entrypoint_call = call(["if", ":entrypoint"], authority, parent_pointer, opts)
    if_expr = expr("if", authority, parent_pointer, opts)
    then_expr = then_expr(context, authority, parent_pointer, opts)
    else_expr = else_expr(context, authority, parent_pointer, opts)

    contexts =
      Enum.flat_map(
        ["if", "then", "else"],
        &List.wrap(if is_map_key(context, &1), do: context(&1, authority, parent_pointer, opts))
      )

    function =
      case opts[:tracked] do
        :object ->
          build_tracked(entrypoint_call, if_expr, then_expr, else_expr)

        :array ->
          build_untracked(entrypoint_call, if_expr, then_expr, else_expr)

        nil ->
          build_untracked(entrypoint_call, if_expr, then_expr, else_expr)
      end

    quote do
      unquote(function)
      unquote(contexts)
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

  defp then_expr(context, authority, parent_pointer, opts) do
    case {context["then"], opts[:tracked]} do
      {nil, :object} ->
        quote do
          {:ok, if_seen}
        end

      {nil, _} ->
        :ok

      {_, true} ->
        then = expr("then", authority, parent_pointer, opts)

        quote do
          require Exonerate.Tools

          case unquote(then) do
            {:ok, then_seen} ->
              {:ok, MapSet.union(if_seen, then_seen)}

            Exonerate.Tools.error_match(error) ->
              error
          end
        end

      _ ->
        expr("then", authority, parent_pointer, opts)
    end
  end

  defp else_expr(context, authority, parent_pointer, opts) do
    case {context["else"], opts[:tracked]} do
      {nil, :object} ->
        quote do
          {:ok, MapSet.new()}
        end

      {nil, _} ->
        :ok

      _ ->
        expr("else", authority, parent_pointer, opts)
    end
  end

  defp expr(what, authority, parent_pointer, opts) do
    quote do
      unquote(call(what, authority, parent_pointer, opts))(content, path)
    end
  end

  defp call(what, authority, parent_pointer, opts) do
    Tools.call(authority, JsonPointer.join(parent_pointer, what), opts)
  end

  defp context(what, authority, parent_pointer, opts) do
    pointer = JsonPointer.join(parent_pointer, what)

    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end
end
