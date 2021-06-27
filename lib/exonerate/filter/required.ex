defmodule Exonerate.Filter.Required do
  @behaviour Exonerate.Filter

  def append_filter(required, validation) when is_list(required) do
    calls = validation.calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = List.insert_at(validation.children, 0, code(required, validation))

    validation
    |> put_in([:calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["required" | validation.path])
  end

  # if string is the only type, avoid the guard.
  defp code(required, validation = %{types: [:object]}) do
    quote do
      defp unquote(name(validation))(object, path) when is_map(object) do
        :ok
      end
    end
  end

  defp code(required, validation) do
    quote do
      defp unquote(name(validation))(object, path) when is_map(object) do
        :ok
      end
      defp unquote(name(validation))(_, _), do: :ok
    end
  end

end
