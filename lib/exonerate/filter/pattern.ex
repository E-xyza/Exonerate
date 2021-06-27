defmodule Exonerate.Filter.Pattern do
  @behaviour Exonerate.Filter

  def append_filter(pattern, validation) when is_binary(pattern) do
    calls = validation.calls
    |> Map.get(:string, [])
    |> List.insert_at(0, name(validation))

    children = List.insert_at(validation.children, 0, code(pattern, validation))

    validation
    |> put_in([:calls, :string], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["pattern" | validation.path])
  end

  # if string is the only type, avoid the guard.
  defp code(pattern, validation = %{types: types}) when types == [:string] do
    quote do
      defp unquote(name(validation))(string, path) when is_binary(string) do
        unless Regex.match?(sigil_r(<<unquote(pattern)>>, []), string) do
          Exonerate.mismatch(string, path)
        end
        :ok
      end
    end
  end

  defp code(pattern, validation) do
    quote do
      defp unquote(name(validation))(string, path) when is_binary(string) do
        unless Regex.match?(sigil_r(<<unquote(pattern)>>, []), string) do
          Exonerate.mismatch(string, path)
        end
        :ok
      end
      defp unquote(name(validation))(_, _), do: :ok
    end
  end
end
