defmodule Exonerate.Type.String do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, :format_binary, pipeline: [], filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Context

  @context_filters ~w(minLength maxLength format pattern)
  @context_modules Map.new(@context_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Context.t(), Type.json()) :: t

  # draft <= 7 refs inhibit type-based analysis
  def parse(context = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: context}
  end

  def parse(context, schema) do
    %__MODULE__{context: context, format_binary: format_binary(schema)}
    |> Tools.collect(@context_filters, fn
      filter, filter when is_map_key(schema, filter) ->
        Filter.parse(filter, @context_modules[filter], schema)

      filter, _ ->
        filter
    end)
  end

  defp format_binary(%{"format" => "binary"}), do: true
  defp format_binary(_), do: false

  @impl true
  @spec compile(t) :: Macro.t()
  def compile(filter = %{format_binary: true}) do
    combining =
      Context.combining(
        filter.context,
        quote do
          string
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote([])(string, path) when is_binary(string) do
        Exonerate.pipeline(string, path, unquote(filter.pipeline))
        unquote_splicing(combining)
      end
    end
  end

  def compile(filter) do
    combining =
      Context.combining(
        filter.context,
        quote do
          string
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote([])(string, path) when is_binary(string) do
        if String.valid?(string) do
          Exonerate.pipeline(string, path, unquote(filter.pipeline))
          unquote_splicing(combining)
        else
          Exonerate.mismatch(string, path)
        end
      end
    end
  end
end
