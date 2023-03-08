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
    then_expr = if context["then"], do: expr("then", authority, parent_pointer, opts), else: :ok

    else_expr =
      if context["else"],
        do: expr("else", authority, parent_pointer, opts),
        else: {:error, [], Elixir}

    quote do
      defp unquote(entrypoint_call)(content, path) do
        case unquote(if_expr) do
          :ok ->
            unquote(then_expr)

          error = {:error, _} ->
            unquote(else_expr)
        end
      end
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
end
