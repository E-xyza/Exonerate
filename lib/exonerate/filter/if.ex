defmodule Exonerate.Filter.If do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    calls = [name(validation) | Map.get(validation.calls, :all, [])]


    validation
    |> put_in([:calls, :all], calls)
    |> put_in([:children], code(schema, validation) ++ validation.children)
  end

  defp name(validation) do
    Exonerate.path_to_call(["if" | validation.path])
  end

  defp then_clause(validation) do
    if then = validation.calls[:then] do
      quote do
        unquote(Enum.at(then, 0))(value, path)
      end
    else
      :ok
    end
  end

  defp else_clause(validation) do
    if else_ = validation.calls[:else] do
      quote do
        unquote(Enum.at(else_, 0))(value, path)
      end
    else
      :ok
    end
  end

  defp code(schema, validation) do
    shim = ["if_" | validation.path]

    [quote do
       defp unquote(name(validation))(value, path) do
         result = try do
           unquote(Exonerate.path_to_call(shim))(value, path)
           true
         catch
           {:error, _} -> false
         end

         if result do
           unquote(then_clause(validation))
         else
           unquote(else_clause(validation))
         end
       end
       unquote(Exonerate.Validation.from_schema(schema, shim))
     end]
  end
end
