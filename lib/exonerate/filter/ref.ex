defmodule Exonerate.Filter.Ref do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :ref]

  alias Exonerate.Registry
  alias Exonerate.Context

  @impl true
  def parse(context, %{"$ref" => ref}) do
    module = %__MODULE__{context: context, ref: ref}

    %{
      context
      | children: [module | context.children],
        combining: [module | context.combining]
    }
  end

  def combining(filter, value_ast, path_ast) do
    # obtain the function call from registry.
    uri =
      case filter.ref do
        "#" -> "/"
        "#" <> rest -> rest
      end

    fun = Registry.request(filter.context.schema, JsonPointer.from_uri(uri))
    ref_path = JsonPointer.to_uri(filter.context.pointer)

    quote do
      result =
        try do
          unquote(fun)(unquote(value_ast), unquote(path_ast))
        catch
          {:error, props} ->
            ref_trace =
              props
              |> Keyword.get(:ref_trace)
              |> List.wrap()

            Keyword.put(props, :ref_trace, [unquote(ref_path) | ref_trace])
        end

      case result do
        :ok ->
          :ok

        list when is_list(list) ->
          throw({:error, list})
      end
    end
  end

  def compile(%__MODULE__{}), do: []
end
