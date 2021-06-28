defmodule Exonerate.Filter.OneOf do
  @moduledoc false

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    calls = validation.calls
    |> Map.get(:all, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:calls, :all], calls)
    |> put_in([:children], children)
  end

  def name(validation) do
    Exonerate.path(["oneOf" | validation.path])
  end

  def code(schema, validation) do
    {calls, funs} = schema
    |> Enum.with_index
    |> Enum.map(fn {subschema, index} ->
      subpath = [to_string(index) , "oneOf" | validation.path]
      {
        {:&, [], [{:/, [], [{Exonerate.path(subpath), [], Elixir}, 2]}]},
        Exonerate.Validation.from_schema(subschema, subpath)
      }
    end)
    |> Enum.unzip

    [quote do
      def unquote(name(validation))(value, path) do
        count = Enum.count(unquote(calls), fn fun ->
          try do
            fun.(value, path)
          catch
            {:error, _} -> false
          end 
        end)
        if (count == 1), do: :ok, else: Exonerate.mismatch(value, path)
      end
    end] ++ funs
  end
end
