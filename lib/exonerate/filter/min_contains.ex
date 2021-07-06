defmodule Exonerate.Filter.MinContains do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(minimum, validation) when is_integer(minimum) do
    %{validation |
      post_accumulate: [name(validation) | (validation.post_accumulate -- contains(validation))],
      children: code(minimum, validation) ++ validation.children}
  end

  defp name(validation) do
    Exonerate.path_to_call(["minContains" | validation.path])
  end

  # minContains overrides the contains value.
  defp contains(validation) do
    [Exonerate.path_to_call(["contains" | validation.path])]
  end

  defp code(minimum, validation) do
    [quote do
      defp unquote(name(validation))(acc = %{contains: contains}, list, path) do
        if contains < unquote(minimum) do
          Exonerate.mismatch(list, path)
        end
      end
      defp unquote(name(validation))(_, _, _), do: :ok
    end]
  end
end
