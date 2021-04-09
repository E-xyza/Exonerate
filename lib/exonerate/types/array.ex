defmodule Exonerate.Types.Array do
  @enforce_keys [:path]
  @params [:contains, :items]

  defstruct @enforce_keys ++ @params

  def build(path, params) do
    items = case params["items"] do
      nil -> nil
      items_list when is_list(items_list) ->
        items_list
        |> Enum.with_index
        |> Enum.map(fn {item, index} ->
          Exonerate.Builder.to_struct(item, :"#{path}-items-#{index}")
        end)
      item ->
        Exonerate.Builder.to_struct(item, :"#{path}-items")
    end

    contains = if contains = params["contains"] do
      Exonerate.Builder.to_struct(contains, :"#{path}-contains")
    end

    %__MODULE__{
      path: path,
      items: items,
      contains: contains
    }
  end

  defimpl Exonerate.Buildable do
    def build(spec = %{path: path}) do
      q = quote do
        defp unquote(path)(content, path) when not is_list(content) do
          {:mismatch, {path, content}}
        end
        defp unquote(path)(list, path) do
          unquote(items_call(spec))
          :ok
        catch
          error = {:mismatch, _} -> error
        end
        unquote_splicing(items_validation(spec.items))
      end

      if spec.path == :tuple do
        q |> Macro.to_string |> IO.puts
      end
      q
    end

    defp items_call(%{items: nil}), do: :ok
    defp items_call(%{items: []}) do
      quote do
        unless list == [], do: throw {:mismatch, {"#", list}}
      end
    end
    defp items_call(_spec = %{items: items}) when is_list(items) do
      tuple_call(items)
    end
    defp items_call(spec = %{items: _}) do
      quote do
        Enum.each(list, fn item ->
          unless (error = unquote(:"#{spec.path}-items")(item, path)) == :ok do
            throw error
          end
        end)
      end
    end

    defp items_validation(nil), do: []
    defp items_validation(spec) when is_list(spec) do
      tuple_validation(spec)
    end
    defp items_validation(spec) do
      [Exonerate.Buildable.build(spec)]
    end

    defp tuple_call([spec | _]) do
      quote do
        unquote(spec.path)(list, path)
      end
    end
    defp tuple_call([]), do: :ok

    defp tuple_validation([spec | rest]) do
      [quote do
        defp unquote(spec.path)(list, path) do
          unless (error = unquote(tuple_call(rest))) == :ok do
            throw error
          end
          :ok
        end
      end | tuple_validation(rest)]
    end
    defp tuple_validation([]), do: []


  end
end
