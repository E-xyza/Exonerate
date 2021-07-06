defmodule Exonerate.Filter.Not do
  @moduledoc false

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(inversion, validation) do
    calls = validation.calls
    |> Map.get(:all, [])
    |> List.insert_at(0, name(validation))

    children = code(inversion, validation) ++ validation.children

    validation
    |> put_in([:calls, :all], calls)
    |> put_in([:children], children)
  end

  def name(validation) do
    Exonerate.path_to_call(["not" | validation.path])
  end

  def code(inversion, validation) do
    inner_path = Exonerate.path_to_call(["not_" | validation.path])
    [quote do
      def unquote(name(validation))(inversion, path) do
        result = try do
          unquote(inner_path)(inversion, path)
        catch
          {:error, _} -> :error
        end
        case result do
          :ok -> Exonerate.mismatch(inversion, path)
          :error -> :ok
        end
      end
    end,
    Exonerate.Validation.from_schema(inversion, ["not_" | validation.path])]
  end
end
