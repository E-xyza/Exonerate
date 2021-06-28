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
    quote do
      defp unquote(Exonerate.path(validation.path))(value, path)
        when value not in unquote(Macro.escape(enum)) do
          Exonerate.mismatch(value, path, guard: "enum")
      end
    end
  end
end
