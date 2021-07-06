defmodule Exonerate.Filter.Const do
  @moduledoc false

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(const, validation) do
    # TODO: HOIST ENUMS TO THE TOP OF THE GUARDS LIST
    # TODO: DO MORE SOPHISTICATED TYPE FILTERING HERE.
    %{validation | guards: [code(const, validation) | validation.guards]}
  end

  defp code(const, validation) do
    # TODO: DO MORE SOPHISTICATED TYPE FILTERING HERE.
    quote do
      defp unquote(Exonerate.path_to_call(validation.path))(value, path)
        when value != unquote(Macro.escape(const)) do
          Exonerate.mismatch(value, path, guard: "const")
      end
    end
  end
end
