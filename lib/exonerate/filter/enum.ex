defmodule Exonerate.Filter.Enum do
  @moduledoc false

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(enum, validation) when is_list(enum) do
    # TODO: HOIST ENUMS TO THE TOP OF THE GUARDS LIST
    # TODO: DO MORE SOPHISTICATED TYPE FILTERING HERE.
    %{validation | guards: [code(enum, validation) | validation.guards]}
  end

  defp code(enum, validation) do
    # TODO: DO MORE SOPHISTICATED TYPE FILTERING HERE.

    # this is due to a bug in erlang compiler.
    true_escape = if true in enum do
      quote do
        defp unquote(Exonerate.path_to_call(validation.path))(true, path), do: :ok
      end
    end

    quote do
      unquote(true_escape)
      defp unquote(Exonerate.path_to_call(validation.path))(value, path)
        when value not in unquote(Macro.escape(enum -- [true])) do
          Exonerate.mismatch(value, path, guard: "enum")
      end
    end
  end
end
