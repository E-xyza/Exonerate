defmodule Exonerate.Filter.Required do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(required_list, resource, pointer, opts) do
    with_clauses = build_with_clauses(required_list, resource, pointer)

    quote do
      defp unquote(Tools.call(resource, pointer, opts))(object, path) do
        unquote(with_clauses)
      end
    end
  end

  defp build_with_clauses(required_list, resource, pointer) do
    clauses =
      required_list
      |> Enum.with_index()
      |> Enum.map(fn {field, index} ->
        error =
          quote do
            require Exonerate.Tools

            Exonerate.Tools.mismatch(
              object,
              unquote(resource),
              {unquote(pointer), unquote("#{index}")},
              path,
              required: Path.join(path, unquote(field))
            )
          end

        {:<-, [],
         [
           :ok,
           quote do
             if is_map_key(object, unquote(field)), do: :ok, else: unquote(error)
           end
         ]}
      end)

    {:with, [], clauses ++ [[do: :ok]]}
  end
end
