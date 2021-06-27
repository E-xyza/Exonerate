defmodule Exonerate.Filter.Type do
  @moduledoc false
  
  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(types_spec, validation) when is_list(types_spec) do
    types = Enum.map(types_spec, &String.to_atom/1)

    type_guard = types
    |> Enum.map(&to_guard/1)
    |> Enum.reduce(&quote do unquote(&1) and unquote(&2) end)

    fun = Exonerate.path([validation.path])

    type_filter = quote do
      defp unquote(fun)(value, path) when unquote(type_guard), do: Exonerate.mismatch(value, path, guard: "type")
    end

    %{validation |
      guards: [type_filter | validation.guards],
      types: Map.new(types, &{&1, []})
    }
  end
  def append_filter(type, validation) do
    type
    |> List.wrap
    |> append_filter(validation)
  end

  @valid_types ~w(array boolean integer null number object string)a

  defp to_guard(type) when type in @valid_types do
    guard = Exonerate.Type.guard(type)
    quote do not unquote(guard)(value) end
  end
  defp to_guard(type), do: raise CompileError, description: "invalid type #{inspect type} found"

end
