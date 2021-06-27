defmodule Exonerate.Filter.MinLength do
  @behaviour Exonerate.Filter

  def append_filter(length, validation) when is_integer(length) do
    calls = validation.calls
    |> Map.get(:string, [])
    |> List.insert_at(0, name(validation))

    children = List.insert_at(validation.children, 0, code(length, validation))

    validation
    |> put_in([:calls, :string], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["minLength" | validation.path])
  end

  # if string is the only type, avoid the guard.
  defp code(length, validation = %{types: types}) when types == [:string] do
    quote do
      defp unquote(name(validation))(string, path) when is_binary(string) do
        if String.length(string) < unquote(length) do
          Exonerate.mismatch(string, path)
        end
        :ok
      end
    end
  end

  defp code(length, validation) do
    quote do
      defp unquote(name(validation))(string, path) when is_binary(string) do
        if String.length(string) < unquote(length) do
          Exonerate.mismatch(string, path)
        end
        :ok
      end
      defp unquote(name(validation))(_, _), do: :ok
    end
  end
end
