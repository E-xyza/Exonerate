defmodule Exonerate.Filter.Type do
  @moduledoc false
  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @impl true
  def filter(%{"type" => type}, state) do
    # establish the list of types that we are actually going to support.  This is
    # strictly for compilation optimization purposes.
    types = for t <- Map.keys(state.types),
              Atom.to_string(t) in List.wrap(type),
              into: %{},
              do: {t, []}

    {[type_filter(types, state.path)], %{state | types: types}}
  end
  def filter(_spec, state), do: {[], state}

  defp type_filter(types, path) do
    type_filter = types
    |> Map.keys
    |> Enum.map(fn
      :array -> quote do is_list(value) end
      :boolean -> quote do is_boolean(value) end
      :integer -> quote do is_integer(value) end
      :null -> quote do is_nil(value) end
      :number -> quote do is_number(value) end
      :object -> quote do is_map(value) end
      :string -> quote do is_binary(value) end
    end)
    |> Enum.reduce(&quote do unquote(&1) or unquote(&2) end)

    quote do
      defp unquote(path)(value, path) when not unquote(type_filter) do
        Exonerate.mismatch(value, path, schema_subpath: "type")
      end
    end
  end

end
